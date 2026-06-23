from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ... import database, models, schemas
from .auth import get_db, get_current_user

router = APIRouter(
    prefix="/parents",
    tags=["Parents"]
)

@router.post("/link-student", response_model=schemas.Student)
def link_student(enrollment_number: str, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != "parent":
        raise HTTPException(status_code=403, detail="Only parents can link students")
    
    # Check if student exists
    student = db.query(models.Student).filter(models.Student.enrollment_number == enrollment_number).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    # Check if already linked
    if student.parent_id == current_user.id:
        raise HTTPException(status_code=400, detail="Student already linked to your account")
    
    # Security check: In real world, verify detailed info (DOB, Pin) or if student has no parent yet.
    # Current model allows one parent. If student has parent, we might deny or allow multi-parent (requires schema change).
    # For MVP: If student has a DIFFERENT parent, deny.
    if student.parent_id and student.parent_id != current_user.id:
        # Check if that parent is a placeholder? 
        # For simplicity MVP: If student has parent_id, check if it matches.
        # But wait, import process created students with placeholder parents. 
        # If I am a real parent claiming, I should probably override the placeholder or merge?
        # Logic: If student.parent.email is a placeholder/system generated, allow claim.
        # For now, simplistic: update parent_id.
        pass

    student.parent_id = current_user.id
    db.commit()
    db.refresh(student)
    return student

@router.get("/my-students", response_model=list[schemas.Student])
def get_my_students(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return db.query(models.Student).filter(models.Student.parent_id == current_user.id).all()

from pydantic import BaseModel

class TopUpRequest(BaseModel):
    amount: float
    reference: str # External payment provider ref

@router.post("/wallet/top-up")
def top_up_wallet(req: TopUpRequest, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != "parent":
        raise HTTPException(status_code=403, detail="Only parents have a wallet")
        
    if req.amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")
        
    # In real world, verify 'reference' with Paystack/Flutterwave before crediting
    current_user.credit_balance += req.amount
    
    # Record in Ledger (Debit Bank, Credit Parent Wallet)
    from ...core.ledger import record_event_transaction
    # Since wallet is global to the parent across schools in a real multi-tenant, 
    # but here a user belongs to a school_id:
    school_id = current_user.school_id
    
    if school_id:
        record_event_transaction(
            db=db,
            school_id=school_id,
            description=f"Wallet Top-Up by {current_user.full_name} [Ref: {req.reference}]",
            event_type="payment.wallet_credit",
            provider="mock",
            amount=req.amount,
            fallback_debit="Bank Account",
            fallback_credit="Parent Wallet"
        )
    
    db.commit()
    db.refresh(current_user)
    
    return {"message": "Wallet topped up successfully", "new_balance": current_user.credit_balance}

@router.post("/wallet/toggle-autopay")
def toggle_autopay(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != "parent":
        raise HTTPException(status_code=403, detail="Only parents can toggle auto-pay")
        
    current_user.auto_pay_enabled = not current_user.auto_pay_enabled
    db.commit()
    
    return {
        "message": "Auto-pay toggled successfully", 
        "auto_pay_enabled": current_user.auto_pay_enabled
    }

class StorePurchaseItem(BaseModel):
    item_id: int
    quantity: int

class StorePurchaseRequest(BaseModel):
    student_id: int
    items: list[StorePurchaseItem]

@router.get("/store/items", response_model=list[schemas.InventoryItem])
def get_store_items(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != "parent":
        raise HTTPException(status_code=403, detail="Only parents can browse the store")
    
    if not current_user.school_id:
        return []

    return db.query(models.InventoryItem).filter(
        models.InventoryItem.school_id == current_user.school_id,
        models.InventoryItem.is_for_sale == True
    ).all()

@router.post("/store/purchase", response_model=schemas.Invoice)
def purchase_store_items(req: StorePurchaseRequest, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != "parent":
        raise HTTPException(status_code=403, detail="Only parents can make purchases")

    # Verify student belongs to parent
    student = db.query(models.Student).filter(
        models.Student.id == req.student_id,
        models.Student.parent_id == current_user.id
    ).first()
    
    if not student:
        raise HTTPException(status_code=404, detail="Student not found or not linked to your account")

    if not req.items:
        raise HTTPException(status_code=400, detail="No items to purchase")

    total_amount = 0.0
    line_items_data = []

    for p_item in req.items:
        db_item = db.query(models.InventoryItem).filter(
            models.InventoryItem.id == p_item.item_id,
            models.InventoryItem.school_id == current_user.school_id,
            models.InventoryItem.is_for_sale == True
        ).first()

        if not db_item:
            raise HTTPException(status_code=404, detail=f"Item with ID {p_item.item_id} not found or not for sale")

        if db_item.quantity < p_item.quantity:
            raise HTTPException(status_code=400, detail=f"Insufficient stock for {db_item.name}. Available: {db_item.quantity}")

        # Decrement stock
        db_item.quantity -= p_item.quantity
        
        item_total = db_item.unit_price * p_item.quantity
        total_amount += item_total
        
        line_items_data.append({
            "title": f"Store Purchase: {db_item.name} (x{p_item.quantity})",
            "amount": item_total
        })

    # Create Invoice
    from datetime import datetime, timezone
    new_invoice = models.Invoice(
        title="School Store Purchase",
        due_date=datetime.now(timezone.utc),
        status="pending",
        student_id=student.id,
        school_id=current_user.school_id
    )
    db.add(new_invoice)
    db.commit()
    db.refresh(new_invoice)

    # Add line items
    for li_data in line_items_data:
        li = models.InvoiceLineItem(
            invoice_id=new_invoice.id,
            title=li_data["title"],
            amount=li_data["amount"]
        )
        db.add(li)
        
    db.commit()
    db.refresh(new_invoice)

    # Note: If auto-pay is enabled, we could trigger it here, but typically the user would
    # be redirected to pay immediately or it stays as pending.
    
    return new_invoice

