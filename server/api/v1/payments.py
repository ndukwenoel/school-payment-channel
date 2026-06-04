from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from .. import database, models, schemas
from .auth import get_db, get_current_user
from datetime import datetime

router = APIRouter(
    prefix="/payments",
    tags=["Payments"]
)

@router.post("/create-intent")
def create_payment_intent(fee_id: int, amount: float, current_user: models.User = Depends(get_current_user)):
    # Mock Gateway Logic
    if amount <= 0:
        raise HTTPException(status_code=400, detail="Invalid amount")
    
    # In real integration, we'd call Stripe/Paystack here.
    # Return a mock client_secret
    return {
        "client_secret": f"mock_secret_{fee_id}_{int(datetime.now().timestamp())}",
        "transaction_id": f"TXN-{int(datetime.now().timestamp())}",
        "gateway": "mock"
    }

@router.post("/confirm", response_model=schemas.Payment)
def confirm_payment(payment: schemas.PaymentCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # This replaces the logic in fees.py/pay but adds user validation
    
    # 1. Verify Fee
    fee = db.query(models.Fee).filter(models.Fee.id == payment.fee_id).first()
    if not fee:
        raise HTTPException(status_code=404, detail="Fee not found")
    
    # 2. Verify Authorization (User must be parent of student)
    if fee.student.parent_id != current_user.id:
         raise HTTPException(status_code=403, detail="Not authorized to pay for this student")

    # 3. Calculate Totals
    total_paid = sum(p.amount_paid for p in fee.payments)
    
    # Net amount calculation
    net_amount = fee.amount
    if fee.discount:
        if fee.discount.percentage > 0:
            net_amount -= (fee.amount * (fee.discount.percentage / 100))
        if fee.discount.flat_amount > 0:
            net_amount -= fee.discount.flat_amount
            
    # 4. Update Status
    if total_paid + payment.amount_paid >= net_amount:
        fee.status = "paid"
    elif total_paid + payment.amount_paid > 0:
        fee.status = "partial"
        
    # 5. Record Payment
    new_payment = models.Payment(
        fee_id=payment.fee_id,
        amount_paid=payment.amount_paid,
        payment_method=payment.payment_method,
        transaction_id=f"TXN-{datetime.now().timestamp()}", # In real world, pass from gateway
        school_id=fee.school_id
    )
    db.add(new_payment)
    db.flush() # Flush to get new_payment.id
    
    db.commit()
    db.refresh(new_payment)
    
    # 6. Dispatch asynchronous event for Ledger processing and other decoupled actions
    from ...events import BaseEvent, EventDispatcher
    event = BaseEvent(
        event_type="PaymentReceived",
        school_id=fee.school_id,
        payload={
            "payment_id": new_payment.id,
            "fee_id": fee.id,
            "fee_title": fee.title,
            "amount": payment.amount_paid,
            "payment_method": payment.payment_method,
            "transaction_id": new_payment.transaction_id,
            "user_email": current_user.email
        }
    )
    EventDispatcher.publish(event)
    
    # 7. Offload receipt generation to Celery Worker
    try:
        from ...worker.tasks import send_payment_receipt
        send_payment_receipt.delay(payment_id=new_payment.id, recipient_email=current_user.email)
    except Exception as e:
        print(f"Failed to queue background task: {e}")
        
    return new_payment

@router.get("/history", response_model=list[schemas.Payment])
def get_payment_history(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # Get all students for parent
    students = db.query(models.Student).filter(models.Student.parent_id == current_user.id).all()
    student_ids = [s.id for s in students]
    
    # Get fees for these students
    fees = db.query(models.Fee).filter(models.Fee.student_id.in_(student_ids)).all()
    fee_ids = [f.id for f in fees]
    
    # Get payments for these fees
    payments = db.query(models.Payment).filter(models.Payment.fee_id.in_(fee_ids)).order_by(models.Payment.payment_date.desc()).all()
    return payments
