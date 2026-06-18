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
