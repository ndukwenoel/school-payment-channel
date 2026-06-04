import time
from .celery_app import celery_app
# In a real scenario, you'd import SQLAlchemy sessions and models here
# to perform actual DB work asynchronously.

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
    
    print(f"[EVENT HANDLER] Processing StudentEnrolled for student {student_id} ({enrollment_number}). Triggering fee generation...")
    
    from ..database import SessionLocal
    from ..models import Fee
    from datetime import datetime, timedelta, timezone
    
    db = SessionLocal()
    try:
        fee_title = f"Registration Fee - {grade}"
        
        # Idempotency check: Don't generate the same fee twice for this student
        existing_fee = db.query(Fee).filter(
            Fee.student_id == student_id,
            Fee.title == fee_title
        ).first()
        
        if existing_fee:
            print(f"[EVENT HANDLER] Fee '{fee_title}' already exists for student {student_id}. Skipping.")
            return
            
        new_fee = Fee(
            title=fee_title,
            amount=500.00,  # Standard registration amount
            due_date=datetime.now(timezone.utc) + timedelta(days=14),
            status="pending",
            student_id=student_id,
            school_id=school_id
        )
        db.add(new_fee)
        db.commit()
        print(f"[EVENT HANDLER] Successfully generated initial fee for student {student_id}.")
    except Exception as e:
        db.rollback()
        print(f"[EVENT HANDLER] Error generating fee: {e}")
        raise
    finally:
        db.close()

def handle_payment_received(payload: dict, school_id: int):
    payment_id = payload.get("payment_id")
    amount = payload.get("amount")
    fee_title = payload.get("fee_title")
    payment_method = payload.get("payment_method")
    
    print(f"[EVENT HANDLER] Processing PaymentReceived for payment {payment_id} (${amount}). Triggering ledger update...")
    
    from ..database import SessionLocal
    from ..core.ledger import record_transaction
    from ..models import LedgerTransaction
    
    db = SessionLocal()
    try:
        # Idempotency check: Ensure we don't process the same payment twice
        description = f"Payment for {fee_title} via {payment_method} [REF:PAY-{payment_id}]"
        
        existing_txn = db.query(LedgerTransaction).filter(
            LedgerTransaction.description == description,
            LedgerTransaction.school_id == school_id
        ).first()
        
        if existing_txn:
            print(f"[EVENT HANDLER] Ledger entry already exists for Payment {payment_id}. Skipping.")
            return
            
        record_transaction(
            db=db,
            school_id=school_id,
            description=description,
            debit_account_name="Parent Wallet" if payment_method == "wallet" else "Bank Account",
            credit_account_name="School Revenue",
            amount=amount
        )
        db.commit()
        print(f"[EVENT HANDLER] Successfully recorded ledger transaction for Payment {payment_id}.")
    except Exception as e:
        db.rollback()
        print(f"[EVENT HANDLER] Error recording ledger transaction: {e}")
        raise
    finally:
        db.close()

def handle_virtual_account_funded(payload: dict, school_id: int):
    student_id = payload.get("student_id")
    account_number = payload.get("account_number")
    amount = payload.get("amount")
    transaction_ref = payload.get("transaction_ref")
    
    print(f"[EVENT HANDLER] Processing VirtualAccountFunded for Student {student_id} (${amount}). Triggering Ledger/Fee Auto-matching...")
    
    from ..database import SessionLocal
    from ..core.ledger import record_transaction
    from ..models import LedgerTransaction, Fee, Payment
    
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
        record_transaction(
            db=db,
            school_id=school_id,
            description=description,
            debit_account_name="Virtual Account Wallet",
            credit_account_name="School Revenue",
            amount=amount
        )
        
        # 3. Auto-match to oldest pending Fee
        pending_fee = db.query(Fee).filter(
            Fee.student_id == student_id,
            Fee.status.in_(["pending", "partial"])
        ).order_by(Fee.due_date.asc()).first()
        
        if pending_fee:
            print(f"[EVENT HANDLER] Auto-matching ${amount} to Fee ID {pending_fee.id}")
            new_payment = Payment(
                fee_id=pending_fee.id,
                amount_paid=amount,
                payment_method="virtual_account",
                transaction_id=f"VAM-{transaction_ref}",
                school_id=school_id
            )
            db.add(new_payment)
            
            # Recalculate status
            total_paid = sum(p.amount_paid for p in pending_fee.payments) + amount
            if total_paid >= pending_fee.amount:
                pending_fee.status = "paid"
            else:
                pending_fee.status = "partial"
                
        db.commit()
        print(f"[EVENT HANDLER] Successfully processed VirtualAccountFunded for Student {student_id}.")
    except Exception as e:
        db.rollback()
        print(f"[EVENT HANDLER] Error processing VAM funding: {e}")
        raise
    finally:
        db.close()
