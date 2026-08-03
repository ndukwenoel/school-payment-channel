import time
from .celery_app import celery_app

@celery_app.task(name="send_payment_receipt")
def send_payment_receipt(payment_id: int, recipient_email: str):
    """
    Simulates sending an email receipt.
    Offloaded to Celery to prevent blocking the main API response.
    """
    print(f"Generating PDF receipt for Payment #{payment_id}...")
    time.sleep(2) # Simulate PDF generation
    print(f"Sending email to {recipient_email}...")
    time.sleep(1) # Simulate network call
    print("Receipt sent successfully.")
    return {"status": "sent", "payment_id": payment_id}

@celery_app.task(name="generate_financial_report")
def generate_financial_report(school_id: int, report_type: str):
    """
    Simulates a heavy operation like aggregating ledger entries for a school.
    """
    print(f"Starting {report_type} report generation for School ID {school_id}...")
    time.sleep(5) # Simulate heavy aggregation query
    report_url = f"https://s3.bucket/reports/school_{school_id}_{report_type}.pdf"
    print(f"Report ready at: {report_url}")
    return {"status": "completed", "url": report_url}

@celery_app.task(name="process_domain_event")
def process_domain_event(event_data: dict):
    """
    Generic consumer for all domain events.
    Routes the event to specific handlers based on event_type.
    """
    event_type = event_data.get("event_type")
    event_id = event_data.get("event_id")
    school_id = event_data.get("school_id")
    payload = event_data.get("payload", {})
    
    print(f"[EVENT CONSUMER] Received event {event_type} [ID: {event_id}] for School {school_id}")
    
    # Event routing logic
    if event_type == "StudentEnrolled":
        handle_student_enrolled(payload, school_id)
    elif event_type == "PaymentReceived":
        handle_payment_received(payload, school_id)
    elif event_type == "VirtualAccountFunded":
        handle_virtual_account_funded(payload, school_id)
    elif event_type == "StudentPromoted":
        handle_student_promoted(payload, school_id)
    elif event_type == "InvoiceOverdue":
        handle_invoice_overdue(payload, school_id)
    else:
        print(f"[EVENT CONSUMER] No handler defined for event type: {event_type}")
        
    return {"status": "processed", "event_id": event_id}

def handle_student_enrolled(payload: dict, school_id: int):
    student_id = payload.get("student_id")
    enrollment_number = payload.get("enrollment_number")
    grade = payload.get("grade")
    
    print(f"[EVENT HANDLER] Processing StudentEnrolled for student {student_id} ({enrollment_number}). Triggering invoice generation...")
    
    from ..database import SessionLocal
    from ..models import Invoice, InvoiceLineItem
    from datetime import datetime, timedelta, timezone
    
    db = SessionLocal()
    try:
        invoice_title = f"Registration Invoice - {grade}"
        
        # Idempotency check: Don't generate the same invoice twice for this student
        existing_invoice = db.query(Invoice).filter(
            Invoice.student_id == student_id,
            Invoice.title == invoice_title
        ).first()
        
        if existing_invoice:
            print(f"[EVENT HANDLER] Invoice '{invoice_title}' already exists for student {student_id}. Skipping.")
            return
            
        new_invoice = Invoice(
            title=invoice_title,
            due_date=datetime.now(timezone.utc) + timedelta(days=14),
            status="pending",
            student_id=student_id,
            school_id=school_id
        )
        db.add(new_invoice)
        db.flush()
        
        line_item = InvoiceLineItem(
            invoice_id=new_invoice.id,
            title="Registration Fee",
            amount=500.00
        )
        db.add(line_item)
        
        db.commit()
        print(f"[EVENT HANDLER] Successfully generated initial invoice for student {student_id}.")
    except Exception as e:
        db.rollback()
        print(f"[EVENT HANDLER] Error generating invoice: {e}")
        raise
    finally:
        db.close()

def _get_posting_rule(db, school_id: int, event_type: str, provider: str, default_debit: str, default_credit: str):
    from ..models import PostingRule
    
    rule = db.query(PostingRule).filter(
        PostingRule.school_id == school_id,
        PostingRule.event_type == event_type,
        PostingRule.provider == provider
    ).first()
    if rule:
        return rule.debit_account_name, rule.credit_account_name
    
    rule = db.query(PostingRule).filter(
        PostingRule.school_id == school_id,
        PostingRule.event_type == event_type,
        PostingRule.provider.is_(None)
    ).first()
    if rule:
        return rule.debit_account_name, rule.credit_account_name
        
    return default_debit, default_credit

def handle_payment_received(payload: dict, school_id: int):
    amount = payload.get("amount")
    provider = payload.get("provider")
    transaction_id = payload.get("transaction_id")
    
    print(f"[EVENT HANDLER] Processing PaymentReceived for transaction {transaction_id} (${amount}). Triggering matching and ledger update...")
    
    from ..database import SessionLocal
    from ..core.ledger import record_event_transaction
    from ..models import LedgerTransaction, PaymentAttempt
    
    db = SessionLocal()
    try:
        description = f"Payment via {provider} [REF:{transaction_id}]"
        
        existing_txn = db.query(LedgerTransaction).filter(
            LedgerTransaction.description == description,
            LedgerTransaction.school_id == school_id
        ).first()
        
        if existing_txn:
            print(f"[EVENT HANDLER] Ledger entry already exists for Payment {transaction_id}. Skipping.")
            return
            
        # Match against a PaymentAttempt
        payment_attempts = db.query(PaymentAttempt).filter(
            PaymentAttempt.transaction_id == transaction_id,
            PaymentAttempt.school_id == school_id
        ).all()
        
        if payment_attempts:
            for payment_attempt in payment_attempts:
                if payment_attempt.status == "success":
                    continue # Already processed
                    
                payment_attempt.status = "success"
                invoice = payment_attempt.invoice
                
                # Recalculate status
                total_paid = sum(p.amount for p in invoice.payment_attempts if p.status == "success")
                total_amount = sum(item.amount for item in invoice.line_items)
                
                # We use attempt.amount for the ledger entry instead of the total payload amount, 
                # which handles both single payments and bundled payments correctly.
                actual_amount = payment_attempt.amount
                
                if total_paid > total_amount:
                    invoice.status = "paid"
                    excess_amount = total_paid - total_amount
                    
                    invoice_portion = actual_amount - excess_amount
                    
                    if invoice_portion > 0:
                        debit_acc, credit_acc = _get_posting_rule(db, school_id, "payment.received", provider, "Bank Account", "School Revenue")
                        record_event_transaction(
                            db=db, school_id=school_id, description=f"{description} (Inv: {invoice.id})",
                            event_type="payment.received", provider=provider, amount=invoice_portion,
                            fallback_debit=debit_acc, fallback_credit=credit_acc
                        )
                    
                    # Overpayment logic
                    debit_acc, credit_acc = _get_posting_rule(db, school_id, "payment.overpayment", provider, "Bank Account", "Parent Wallet")
                    record_event_transaction(
                        db=db, school_id=school_id, description=f"{description} (Overpayment Wallet Credit)",
                        event_type="payment.overpayment", provider=provider, amount=excess_amount,
                        fallback_debit=debit_acc, fallback_credit=credit_acc
                    )
                    
                    # Flag for manual review in the Exception Queue (Unreconciled Funds)
                    debit_acc, credit_acc = _get_posting_rule(db, school_id, "payment.exception", provider, "Parent Wallet", "Unreconciled Funds")
                    record_event_transaction(
                        db=db, school_id=school_id, description=f"Exception: Overpayment Review [REF:EXC-OVP-{transaction_id}-{invoice.id}]",
                        event_type="payment.exception", provider=provider, amount=excess_amount,
                        fallback_debit=debit_acc, fallback_credit=credit_acc
                    )
                    print(f"[EVENT HANDLER] Overpayment of ${excess_amount} detected and flagged.")
                else:
                    if total_paid == total_amount:
                        invoice.status = "paid"
                    else:
                        invoice.status = "partial"
                        
                    debit_acc, credit_acc = _get_posting_rule(db, school_id, "payment.received", provider, "Bank Account", "School Revenue")
                    record_event_transaction(
                        db=db,
                        school_id=school_id,
                        description=f"{description} (Inv: {invoice.id})",
                        event_type="payment.received",
                        provider=provider,
                        amount=actual_amount,
                        fallback_debit=debit_acc,
                        fallback_credit=credit_acc
                    )
                print(f"[EVENT HANDLER] Successfully matched transaction {transaction_id} to Invoice {invoice.id} and recorded ledger.")
            
            # If it was a bundle, mark bundle as paid
            if transaction_id.startswith("BNDL-"):
                from ..models import PaymentBundle
                bundle = db.query(PaymentBundle).filter(PaymentBundle.reference == transaction_id).first()
                if bundle:
                    bundle.status = "paid"
        else:
            # Exception Handling: No matching payment attempt found
            print(f"[EVENT HANDLER] Exception: Unmatched {provider} transaction {transaction_id}. Routing to Unreconciled Funds.")
            debit_acc, credit_acc = _get_posting_rule(db, school_id, "payment.exception", provider, "Bank Account", "Unreconciled Funds")
            record_event_transaction(
                db=db,
                school_id=school_id,
                description=f"Exception: Unmatched {provider} Payment [REF:EXC-{transaction_id}]",
                event_type="payment.exception",
                provider=provider,
                amount=amount,
                fallback_debit=debit_acc,
                fallback_credit=credit_acc
            )
            
        db.commit()
    except Exception as e:
        db.rollback()
        print(f"[EVENT HANDLER] Error matching payment transaction: {e}")
        raise
    finally:
        db.close()

def handle_virtual_account_funded(payload: dict, school_id: int):
    student_id = payload.get("student_id")
    account_number = payload.get("account_number")
    amount = float(payload.get("amount", 0.0))
    transaction_ref = payload.get("transaction_ref")
    
    print(f"[EVENT HANDLER] Processing VirtualAccountFunded for Student {student_id} (${amount}). Triggering Ledger/Invoice Auto-matching...")
    
    from ..database import SessionLocal
    from ..core.ledger import record_event_transaction
    from ..models import LedgerTransaction, Invoice, PaymentAttempt, Student
    from datetime import datetime, timezone
    
    db = SessionLocal()
    try:
        # 1. Idempotency Check on Ledger
        description = f"Virtual Account Transfer via {account_number} [REF:VAM-{transaction_ref}]"
        existing_txn = db.query(LedgerTransaction).filter(
            LedgerTransaction.description == description,
            LedgerTransaction.school_id == school_id
        ).first()
        
        if existing_txn:
            print(f"[EVENT HANDLER] Ledger entry already exists for VAM Txn {transaction_ref}. Skipping.")
            return
            
        # 2. Write to Ledger (Main Entry)
        debit_acc, credit_acc = _get_posting_rule(db, school_id, "virtual_account.funded", "virtual_account", "Virtual Account Wallet", "School Revenue")
        record_event_transaction(
            db=db,
            school_id=school_id,
            description=description,
            event_type="virtual_account.funded",
            provider="virtual_account",
            amount=amount,
            fallback_debit=debit_acc,
            fallback_credit=credit_acc
        )
        
        # 3. Auto-match to invoices (oldest first)
        pending_invoices = db.query(Invoice).filter(
            Invoice.student_id == student_id,
            Invoice.status.in_(["pending", "partial"])
        ).order_by(Invoice.due_date.asc()).all()
        
        remaining_amount = amount
        for inv in pending_invoices:
            if remaining_amount <= 0:
                break
                
            total_paid = sum(p.amount for p in inv.payment_attempts if p.status == "success")
            net_amount = sum(item.amount for item in inv.line_items)
            if inv.discount:
                if inv.discount.percentage > 0:
                    net_amount -= (net_amount * (inv.discount.percentage / 100))
                if inv.discount.flat_amount > 0:
                    net_amount -= inv.discount.flat_amount
                    
            amount_due = net_amount - total_paid
            if amount_due <= 0:
                continue
                
            amount_to_apply = min(amount_due, remaining_amount)
            
            new_payment = PaymentAttempt(
                invoice_id=inv.id,
                amount=amount_to_apply,
                provider="virtual_account",
                transaction_id=f"VAM-{transaction_ref}-{inv.id}",
                school_id=school_id,
                status="success",
                payment_date=datetime.now(timezone.utc)
            )
            db.add(new_payment)
            
            if amount_to_apply >= amount_due:
                inv.status = "paid"
            else:
                inv.status = "partial"
                
            remaining_amount -= amount_to_apply
            print(f"[EVENT HANDLER] Auto-matched ${amount_to_apply} to Invoice ID {inv.id}")

        # 4. Handle excess funds
        if remaining_amount > 0:
            print(f"[EVENT HANDLER] ${remaining_amount} remains unapplied. Crediting parent wallet.")
            student = db.query(Student).filter(Student.id == student_id).first()
            if student and student.parent:
                student.parent.credit_balance += remaining_amount
                
            debit_acc, credit_acc = _get_posting_rule(db, school_id, "payment.overpayment", "virtual_account", "School Revenue", "Parent Wallet")
            record_event_transaction(
                db=db, school_id=school_id, description=f"{description} (Overpayment Credit)",
                event_type="payment.overpayment", provider="virtual_account", amount=remaining_amount,
                fallback_debit=debit_acc, fallback_credit=credit_acc
            )
                
        db.commit()
        print(f"[EVENT HANDLER] Successfully processed VirtualAccountFunded for Student {student_id}.")
    except Exception as e:
        db.rollback()
        print(f"[EVENT HANDLER] Error processing VAM funding: {e}")
        raise
    finally:
        db.close()

def handle_student_promoted(payload: dict, school_id: int):
    student_id = payload.get("student_id")
    new_grade = payload.get("new_grade")
    
    print(f"[EVENT HANDLER] Processing StudentPromoted for student {student_id} to {new_grade}. Generating Term 1 Invoice...")
    
    from ..database import SessionLocal
    from ..models import Invoice, InvoiceLineItem
    from datetime import datetime, timedelta, timezone
    
    db = SessionLocal()
    try:
        invoice_title = f"Term 1 Tuition Invoice - {new_grade}"
        
        # Idempotency check
        existing_invoice = db.query(Invoice).filter(
            Invoice.student_id == student_id,
            Invoice.title == invoice_title
        ).first()
        
        if existing_invoice:
            print(f"[EVENT HANDLER] Invoice '{invoice_title}' already exists for student {student_id}. Skipping.")
            return
            
        new_invoice = Invoice(
            title=invoice_title,
            due_date=datetime.now(timezone.utc) + timedelta(days=30), # Give them 30 days
            status="pending",
            student_id=student_id,
            school_id=school_id
        )
        db.add(new_invoice)
        db.flush()
        
        # Standard line items for a new term
        line_items = [
            InvoiceLineItem(invoice_id=new_invoice.id, title="Tuition Fee", amount=1500.00),
            InvoiceLineItem(invoice_id=new_invoice.id, title="Library Fee", amount=100.00),
            InvoiceLineItem(invoice_id=new_invoice.id, title="Technology Fee", amount=50.00)
        ]
        db.add_all(line_items)
        db.commit()
        print(f"[EVENT HANDLER] Successfully generated Term 1 invoice for promoted student {student_id}.")
    except Exception as e:
        db.rollback()
        print(f"[EVENT HANDLER] Error generating invoice on promotion: {e}")
        raise
    finally:
        db.close()

def handle_invoice_overdue(payload: dict, school_id: int):
    invoice_id = payload.get("invoice_id")
    
    print(f"[EVENT HANDLER] Processing InvoiceOverdue for invoice {invoice_id}. Sending reminder...")
    
    from ..database import SessionLocal
    from ..models import Invoice, NotificationLog
    
    db = SessionLocal()
    try:
        invoice = db.query(Invoice).filter(Invoice.id == invoice_id).first()
        if not invoice or invoice.status not in ["pending", "partial"]:
            return
            
        student = invoice.student
        
        if student and student.parent:
            log = NotificationLog(
                recipient_email=student.parent.email,
                subject=f"OVERDUE NOTICE: {invoice.title}",
                message=f"Dear {student.parent.full_name}, your invoice '{invoice.title}' is now overdue. Please settle the outstanding balance immediately.",
                status="sent",
                school_id=school_id
            )
            db.add(log)
            
        invoice.status = "overdue"
        db.commit()
        print(f"[EVENT HANDLER] Invoice {invoice_id} marked as overdue and reminder logged.")
    except Exception as e:
        db.rollback()
        print(f"[EVENT HANDLER] Error handling overdue invoice: {e}")
        raise
    finally:
        db.close()

@celery_app.task(name="sweep_overdue_invoices")
def sweep_overdue_invoices():
    """
    Cron task that runs daily to find overdue invoices and dispatch events.
    """
    print("[CRON] Sweeping for overdue invoices...")
    
    from ..database import SessionLocal
    from ..models import Invoice
    from datetime import datetime, timezone
    from ..events import BaseEvent, EventDispatcher
    
    db = SessionLocal()
    try:
        now = datetime.now(timezone.utc)
        invoices = db.query(Invoice).filter(
            Invoice.status.in_(["pending", "partial"])
        ).all()
        
        overdue_invoices = []
        for inv in invoices:
            is_overdue = False
            if inv.installment_plan:
                for inst in inv.installment_plan.installments:
                    if inst.status == "pending" and inst.due_date < now:
                        is_overdue = True
                        break
            else:
                if inv.due_date < now:
                    is_overdue = True
                    
            if is_overdue:
                overdue_invoices.append(inv)
        
        count = 0
        for invoice in overdue_invoices:
            event = BaseEvent(
                event_type="InvoiceOverdue",
                school_id=invoice.school_id,
                payload={
                    "invoice_id": invoice.id,
                    "student_id": invoice.student_id
                }
            )
            EventDispatcher.publish(event)
            count += 1
            
        print(f"[CRON] Found {count} overdue invoices and dispatched events.")
    except Exception as e:
        print(f"[CRON] Error sweeping overdue invoices: {e}")
    finally:
        db.close()

@celery_app.task(name="bulk_generate_invoices")
def bulk_generate_invoices(invoice_data: dict, school_id: int):
    """
    Bulk generates invoices for all students in a given grade.
    """
    print(f"[EVENT HANDLER] Processing Bulk Invoice Generation for Grade: {invoice_data.get('grade')} in School: {school_id}")
    from ..database import SessionLocal
    from ..models import Invoice, InvoiceLineItem, Student, NotificationLog
    from datetime import datetime
    
    db = SessionLocal()
    try:
        grade = invoice_data.get("grade")
        title = invoice_data.get("title")
        due_date_str = invoice_data.get("due_date")
        discount_id = invoice_data.get("discount_id")
        line_items_data = invoice_data.get("line_items", [])
        
        # Handle ISO format conversion safely
        if due_date_str.endswith('Z'):
            due_date_str = due_date_str[:-1] + '+00:00'
        due_date = datetime.fromisoformat(due_date_str)
        
        students = db.query(Student).filter(
            Student.grade == grade, 
            Student.school_id == school_id
        ).all()
        
        if not students:
            print(f"[EVENT HANDLER] No students found in grade {grade}. Aborting bulk generation.")
            return {"status": "completed", "count": 0}

        count = 0
        for student in students:
            new_invoice = Invoice(
                title=title,
                due_date=due_date,
                student_id=student.id,
                discount_id=discount_id,
                school_id=school_id,
                status="pending"
            )
            db.add(new_invoice)
            db.flush()
            
            for item in line_items_data:
                line_item = InvoiceLineItem(
                    invoice_id=new_invoice.id,
                    title=item.get("title"),
                    amount=item.get("amount")
                )
                db.add(line_item)
            
            # Log notification
            if student.parent:
                log = NotificationLog(
                    recipient_email=student.parent.email,
                    subject=f"New Invoice Assigned: {title}",
                    message=f"A new invoice has been assigned to {student.full_name} due by {due_date.strftime('%Y-%m-%d')}.",
                    status="sent",
                    school_id=school_id
                )
                db.add(log)
                
            count += 1
        
        db.commit()
        print(f"[EVENT HANDLER] Successfully generated {count} invoices for grade {grade}.")
        return {"status": "completed", "count": count}
    except Exception as e:
        db.rollback()
        print(f"[EVENT HANDLER] Error in bulk_generate_invoices: {e}")
        raise
    finally:
        db.close()
