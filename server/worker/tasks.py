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

def handle_payment_received(payload: dict, school_id: int):
    payment_id = payload.get("payment_id")
    amount = payload.get("amount")
    provider = payload.get("provider")
    transaction_id = payload.get("transaction_id")
    
    print(f"[EVENT HANDLER] Processing PaymentReceived for transaction {transaction_id} (${amount}). Triggering matching and ledger update...")
    
    from ..database import SessionLocal
    from ..core.ledger import record_event_transaction
    from ..models import LedgerTransaction, PaymentAttempt, Invoice
    
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
        payment_attempt = db.query(PaymentAttempt).filter(
            PaymentAttempt.transaction_id == transaction_id,
            PaymentAttempt.school_id == school_id
        ).first()
        
        if payment_attempt:
            payment_attempt.status = "success"
            invoice = payment_attempt.invoice
            
            # Recalculate status
            total_paid = sum(p.amount for p in invoice.payment_attempts if p.status == "success")
            total_amount = sum(item.amount for item in invoice.line_items)
            
            if total_paid >= total_amount:
                invoice.status = "paid"
            else:
                invoice.status = "partial"
                
            record_event_transaction(
                db=db,
                school_id=school_id,
                description=description,
                event_type="payment.received",
                provider=provider,
                amount=amount,
                fallback_debit="Bank Account",
                fallback_credit="School Revenue"
            )
            print(f"[EVENT HANDLER] Successfully matched transaction {transaction_id} to Invoice {invoice.id} and recorded ledger.")
        else:
            # Exception Handling: No matching payment attempt found
            print(f"[EVENT HANDLER] Exception: Unmatched {provider} transaction {transaction_id}. Routing to Unreconciled Funds.")
            record_event_transaction(
                db=db,
                school_id=school_id,
                description=f"Exception: Unmatched {provider} Payment [REF:EXC-{transaction_id}]",
                event_type="payment.exception",
                provider=provider,
                amount=amount,
                fallback_debit="Bank Account",
                fallback_credit="Unreconciled Funds"
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
    amount = payload.get("amount")
    transaction_ref = payload.get("transaction_ref")
    
    print(f"[EVENT HANDLER] Processing VirtualAccountFunded for Student {student_id} (${amount}). Triggering Ledger/Invoice Auto-matching...")
    
    from ..database import SessionLocal
    from ..core.ledger import record_event_transaction
    from ..models import LedgerTransaction, Invoice, PaymentAttempt
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
            
        # 2. Write to Ledger
        record_event_transaction(
            db=db,
            school_id=school_id,
            description=description,
            event_type="virtual_account.funded",
            provider="virtual_account",
            amount=amount,
            fallback_debit="Virtual Account Wallet",
            fallback_credit="School Revenue"
        )
        
        # 3. Auto-match to oldest pending Invoice
        pending_invoice = db.query(Invoice).filter(
            Invoice.student_id == student_id,
            Invoice.status.in_(["pending", "partial"])
        ).order_by(Invoice.due_date.asc()).first()
        
        if pending_invoice:
            print(f"[EVENT HANDLER] Auto-matching ${amount} to Invoice ID {pending_invoice.id}")
            new_payment = PaymentAttempt(
                invoice_id=pending_invoice.id,
                amount=amount,
                provider="virtual_account",
                transaction_id=f"VAM-{transaction_ref}",
                school_id=school_id,
                status="success",
                payment_date=datetime.now(timezone.utc)
            )
            db.add(new_payment)
            
            # Recalculate status
            total_paid = sum(p.amount for p in pending_invoice.payment_attempts if p.status == "success") + amount
            total_amount = sum(item.amount for item in pending_invoice.line_items)
            
            if total_paid >= total_amount:
                pending_invoice.status = "paid"
            else:
                pending_invoice.status = "partial"
        else:
            # Exception Handling: No pending invoice found
            print(f"[EVENT HANDLER] Exception: No pending invoices found for Student {student_id}. Flagging for manual review.")
            record_event_transaction(
                db=db,
                school_id=school_id,
                description=f"Exception: Unmatched VA Funding for Student {student_id} [REF:EXC-{transaction_ref}]",
                event_type="payment.exception",
                provider="virtual_account",
                amount=amount,
                fallback_debit="School Revenue", # Reverse the revenue credit
                fallback_credit="Unreconciled Funds"
            )
                
        db.commit()
        print(f"[EVENT HANDLER] Successfully processed VirtualAccountFunded for Student {student_id}.")
    except Exception as e:
        db.rollback()
        print(f"[EVENT HANDLER] Error processing VAM funding: {e}")
        raise
    finally:
        db.close()
