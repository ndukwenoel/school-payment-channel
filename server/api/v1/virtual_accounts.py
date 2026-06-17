from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from .. import database, models, schemas
from .auth import get_db, get_current_user
from ...services.collection import CollectionService

router = APIRouter(
    prefix="/virtual-accounts",
    tags=["Virtual Accounts"]
)

@router.post("/request/{student_id}", response_model=schemas.VirtualAccount)
def request_virtual_account(student_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return CollectionService.request_virtual_account(db=db, student_id=student_id, current_user=current_user)

@router.post("/webhook")
async def payment_webhook(request: Request, db: Session = Depends(get_db)):
    """
    Endpoint for bank/gateway to notify us when a transfer is made to a Virtual Account.
    """
    payload = await request.json()
    
    # In reality, verify webhook signature here
    return CollectionService.process_virtual_account_webhook(db=db, payload=payload)
