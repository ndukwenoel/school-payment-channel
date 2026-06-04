from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from .. import database, models, schemas
from .auth import get_db, get_current_user
import uuid

router = APIRouter(
    prefix="/virtual-accounts",
    tags=["Virtual Accounts"]
)

@router.post("/request/{student_id}", response_model=schemas.VirtualAccount)
def request_virtual_account(student_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # 1. Verify student and authorization
    student = db.query(models.Student).filter(models.Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
        
    if student.parent_id != current_user.id and current_user.role not in ["admin", "school_admin"]:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    # 2. Check if account already exists
    existing = db.query(models.VirtualAccount).filter(models.VirtualAccount.student_id == student_id).first()
    if existing:
        return existing
        
    # 3. Call external gateway (e.g., Paystack/Flutterwave) to generate virtual account
    # Mocking external call
    account_number = str(uuid.uuid4().int)[:10] # Mock 10 digit number
    
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

@router.post("/webhook")
async def payment_webhook(request: Request, db: Session = Depends(get_db)):
    """
    Endpoint for bank/gateway to notify us when a transfer is made to a Virtual Account.
    """
    payload = await request.json()
    
    # In reality, verify webhook signature here
    
    account_number = payload.get("account_number")
    amount = payload.get("amount")
    transaction_ref = payload.get("transaction_ref")
    
    va = db.query(models.VirtualAccount).filter(models.VirtualAccount.account_number == account_number).first()
    if not va:
        raise HTTPException(status_code=404, detail="Virtual Account not found")
        
    # Instead of creating payment synchronously, dispatch event.
    from ...events import BaseEvent, EventDispatcher
    
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
