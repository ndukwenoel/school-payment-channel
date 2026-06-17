from sqlalchemy.orm import Session
from fastapi import HTTPException
from datetime import datetime
import uuid

from .. import models, schemas
from ..events import BaseEvent, EventDispatcher
from ..worker.tasks import send_payment_receipt
from .payment_adapters import get_payment_adapter

class CollectionService:
    @staticmethod
    def create_payment_intent(db: Session, invoice_id: int, amount: float, current_user: models.User, provider: str = "paystack"):
        if amount <= 0:
            raise HTTPException(status_code=400, detail="Invalid amount")
            
        invoice = db.query(models.Invoice).filter(models.Invoice.id == invoice_id).first()
        if not invoice:
            raise HTTPException(status_code=404, detail="Invoice not found")
            
        # Optional: check if user is authorized to pay for this student
        
        adapter = get_payment_adapter(provider)
        intent = adapter.create_payment_intent(invoice_id=invoice_id, amount=amount, customer_email=current_user.email)
        
        # Log the attempt in the database
        attempt = models.PaymentAttempt(
            invoice_id=invoice_id,
            amount=amount,
            provider=provider,
            transaction_id=intent.get("reference") or intent.get("transaction_id"),
            status="pending",
            school_id=invoice.school_id
        )
        db.add(attempt)
        db.commit()
        db.refresh(attempt)
        
        return intent

    @staticmethod
    def confirm_payment(db: Session, payment: schemas.PaymentAttemptCreate, current_user: models.User):
        # This was the old synchronous confirm payment. We still keep it for manual offline payments, 
        # but change it to work with Invoices and PaymentAttempts.
        
        invoice = db.query(models.Invoice).filter(models.Invoice.id == payment.invoice_id).first()
        if not invoice:
            raise HTTPException(status_code=404, detail="Invoice not found")
        
        if invoice.student.parent_id != current_user.id and current_user.role not in ["admin", "school_admin"]:
             raise HTTPException(status_code=403, detail="Not authorized to pay for this student")

        # 3. Calculate Totals
        total_paid = sum(p.amount for p in invoice.payment_attempts if p.status == "success")
        
        # Net amount calculation
        net_amount = sum(item.amount for item in invoice.line_items)
        if invoice.discount:
            if invoice.discount.percentage > 0:
                net_amount -= (net_amount * (invoice.discount.percentage / 100))
            if invoice.discount.flat_amount > 0:
                net_amount -= invoice.discount.flat_amount
                
        # 4. Update Status
        if total_paid + payment.amount_paid >= net_amount:
            invoice.status = "paid"
        elif total_paid + payment.amount_paid > 0:
            invoice.status = "partial"
            
        # 5. Record Payment
        new_attempt = models.PaymentAttempt(
            invoice_id=payment.invoice_id,
            amount=payment.amount,
            provider=payment.provider, # Or 'manual'
            transaction_id=f"TXN-{datetime.now().timestamp()}",
            school_id=invoice.school_id,
            status="success"
        )
        db.add(new_attempt)
        db.flush()
        
        db.commit()
        db.refresh(new_attempt)
        
        # 6. Dispatch event
        event = BaseEvent(
            event_type="PaymentReceived",
            school_id=invoice.school_id,
            payload={
                "payment_id": new_attempt.id,
                "invoice_id": invoice.id,
                "amount": payment.amount,
                "provider": new_attempt.provider,
                "transaction_id": new_attempt.transaction_id,
                "user_email": current_user.email
            }
        )
        EventDispatcher.publish(event)
        
        # 7. Offload receipt generation
        try:
            send_payment_receipt.delay(payment_id=new_attempt.id, recipient_email=current_user.email)
        except Exception as e:
            print(f"Failed to queue background task: {e}")
            
        return new_attempt

    @staticmethod
    def get_payment_history(db: Session, current_user: models.User):
        students = db.query(models.Student).filter(models.Student.parent_id == current_user.id).all()
        student_ids = [s.id for s in students]
        
        invoices = db.query(models.Invoice).filter(models.Invoice.student_id.in_(student_ids)).all()
        invoice_ids = [i.id for i in invoices]
        
        attempts = db.query(models.PaymentAttempt).filter(models.PaymentAttempt.invoice_id.in_(invoice_ids)).order_by(models.PaymentAttempt.payment_date.desc()).all()
        return attempts

    @staticmethod
    def request_virtual_account(db: Session, student_id: int, current_user: models.User):
        student = db.query(models.Student).filter(models.Student.id == student_id).first()
        if not student:
            raise HTTPException(status_code=404, detail="Student not found")
            
        if student.parent_id != current_user.id and current_user.role not in ["admin", "school_admin"]:
            raise HTTPException(status_code=403, detail="Not authorized")
            
        existing = db.query(models.VirtualAccount).filter(models.VirtualAccount.student_id == student_id).first()
        if existing:
            return existing
            
        account_number = str(uuid.uuid4().int)[:10]
        
        new_va = models.VirtualAccount(
            account_number=account_number,
            account_name=f"{student.full_name} - {student.enrollment_number}",
            bank_name="Mock Bank Plc",
            student_id=student_id,
            school_id=student.school_id
        )
        db.add(new_va)
        db.commit()
        db.refresh(new_va)
        
        return new_va

    @staticmethod
    def process_virtual_account_webhook(db: Session, payload: dict):
        account_number = payload.get("account_number")
        amount = payload.get("amount")
        transaction_ref = payload.get("transaction_ref")
        
        va = db.query(models.VirtualAccount).filter(models.VirtualAccount.account_number == account_number).first()
        if not va:
            raise HTTPException(status_code=404, detail="Virtual Account not found")
            
        event = BaseEvent(
            event_type="VirtualAccountFunded",
            school_id=va.school_id,
            payload={
                "student_id": va.student_id,
                "account_number": account_number,
                "amount": amount,
                "transaction_ref": transaction_ref
            }
        )
        EventDispatcher.publish(event)
        
        return {"status": "success", "message": "Webhook processed via event queue"}
