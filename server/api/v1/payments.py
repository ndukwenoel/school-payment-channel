from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ... import database, models, schemas
from .auth import get_db, get_current_user
from ...services.collection import CollectionService

router = APIRouter(
    prefix="/payments",
    tags=["Payments"]
)

@router.post("/create-intent")
def create_payment_intent(invoice_id: int, amount: float, provider: str = "paystack", db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return CollectionService.create_payment_intent(db=db, invoice_id=invoice_id, amount=amount, current_user=current_user, provider=provider)

@router.post("/confirm", response_model=schemas.PaymentAttempt)
def confirm_payment(payment: schemas.PaymentAttemptCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return CollectionService.confirm_payment(db=db, payment=payment, current_user=current_user)

@router.get("/history", response_model=list[schemas.PaymentAttempt])
def get_payment_history(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return CollectionService.get_payment_history(db=db, current_user=current_user)

@router.get("/pending-manual", response_model=list[schemas.PaymentAttempt])
def get_pending_manual_payments(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return CollectionService.get_pending_manual_payments(db=db, current_user=current_user)

@router.post("/manual-transfer", response_model=schemas.PaymentAttempt)
def submit_manual_payment(data: schemas.ManualPaymentCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return CollectionService.submit_manual_payment(db=db, data=data, current_user=current_user)

@router.post("/{payment_id}/verify", response_model=schemas.PaymentAttempt)
def verify_manual_payment(payment_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return CollectionService.verify_manual_payment(db=db, payment_id=payment_id, current_user=current_user)

@router.post("/bundle", response_model=schemas.PaymentBundleResponse)
def create_payment_bundle(bundle_data: schemas.PaymentBundleCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return CollectionService.create_payment_bundle(db=db, invoice_ids=bundle_data.invoice_ids, current_user=current_user)

@router.get("/unmatched")
def get_unmatched_payments(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role not in ["admin", "bursar"]:
        raise HTTPException(status_code=403, detail="Not authorized")
    unmatched = db.query(models.UnmatchedPayment).filter(
        models.UnmatchedPayment.school_id == current_user.school_id,
        models.UnmatchedPayment.status == "pending"
    ).all()
    # Return as dict since we don't have a Pydantic schema for it yet
    return [
        {
            "id": p.id,
            "amount": p.amount,
            "bank_name": p.bank_name,
            "account_number": p.account_number,
            "transaction_ref": p.transaction_ref,
            "narration": p.narration,
            "created_at": p.created_at,
            "classroom_id": p.classroom_id
        }
        for p in unmatched
    ]

@router.post("/unmatched/{payment_id}/resolve")
def resolve_unmatched_payment(payment_id: int, student_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role not in ["admin", "bursar"]:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    payment = db.query(models.UnmatchedPayment).filter(
        models.UnmatchedPayment.id == payment_id,
        models.UnmatchedPayment.school_id == current_user.school_id,
        models.UnmatchedPayment.status == "pending"
    ).first()
    
    if not payment:
        raise HTTPException(status_code=404, detail="Unmatched payment not found or already resolved")
        
    student = db.query(models.Student).filter(
        models.Student.id == student_id,
        models.Student.school_id == current_user.school_id
    ).first()
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
        
    payment.status = "resolved"
    payment.resolved_by_user_id = current_user.id
    
    # Fire the event as if it was a VirtualAccountFunded event
    from ...events import BaseEvent, EventDispatcher
    event = BaseEvent(
        event_type="VirtualAccountFunded",
        payload={
            "student_id": student.id,
            "school_id": payment.school_id,
            "amount": payment.amount,
            "reference": payment.transaction_ref,
            "channel": "bank_transfer_manual_resolve"
        }
    )
    EventDispatcher.publish(event)
    
    db.commit()
    return {"status": "success", "message": "Payment resolved and routed"}
