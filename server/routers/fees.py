from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from .. import database, models, schemas
from datetime import datetime
from .auth import get_current_user

router = APIRouter(
    prefix="/fees",
    tags=["Fees"]
)

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=schemas.Fee)
def create_fee(fee: schemas.FeeCreate, db: Session = Depends(get_db)):
    # Verify student
    student = db.query(models.Student).filter(models.Student.id == fee.student_id).first()
    if not student:
         raise HTTPException(status_code=404, detail="Student not found")

    new_fee = models.Fee(
        title=fee.title,
        amount=fee.amount,
        due_date=fee.due_date,
        student_id=fee.student_id,
        discount_id=fee.discount_id,
        status="pending"
    )
    db.add(new_fee)
    db.commit()
    db.refresh(new_fee)
    return new_fee

@router.post("/bulk", response_model=dict)
def create_bulk_fees(fee_data: schemas.FeeBulkCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # Verify user is admin/school_admin
    if current_user.role not in ["admin", "school_admin"]:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    if current_user.school_id is None:
         raise HTTPException(status_code=400, detail="User not assigned to a school")

    # Find students in grade
    students = db.query(models.Student).filter(
        models.Student.grade == fee_data.grade, 
        models.Student.school_id == current_user.school_id
    ).all()
    
    if not students:
        return {"message": "No students found in this grade", "count": 0}

    count = 0
    for student in students:
        new_fee = models.Fee(
            title=fee_data.title,
            amount=fee_data.amount,
            due_date=fee_data.due_date,
            student_id=student.id,
            discount_id=fee_data.discount_id,
            status="pending"
        )
        db.add(new_fee)
        count += 1
    
    db.commit()
    return {"message": "Fees assigned successfully", "count": count}

@router.get("/student/{student_id}", response_model=List[schemas.Fee])
def get_student_fees(student_id: int, db: Session = Depends(get_db)):
    fees = db.query(models.Fee).filter(models.Fee.student_id == student_id).all()
    # Logic to adjust amount based on discount could go here or in frontend
    # For now returning raw fee data
    return fees

@router.post("/pay", response_model=schemas.Payment)
def pay_fee(payment: schemas.PaymentCreate, db: Session = Depends(get_db)):
    fee = db.query(models.Fee).filter(models.Fee.id == payment.fee_id).first()
    if not fee:
        raise HTTPException(status_code=404, detail="Fee not found")
    
    # Calculate Total Paid so far
    total_paid = sum(p.amount_paid for p in fee.payments)
    
    # Calculate Net Amount Due (after discount)
    net_amount = fee.amount
    if fee.discount:
        if fee.discount.percentage > 0:
            net_amount -= (fee.amount * (fee.discount.percentage / 100))
        if fee.discount.flat_amount > 0:
            net_amount -= fee.discount.flat_amount
    
    new_total_paid = total_paid + payment.amount_paid
    
    # Update Status
    if new_total_paid >= net_amount:
        fee.status = "paid"
    elif new_total_paid > 0:
        fee.status = "partial"
    
    new_payment = models.Payment(
        fee_id=payment.fee_id,
        amount_paid=payment.amount_paid,
        payment_method=payment.payment_method,
        transaction_id=f"TXN-{datetime.now().timestamp()}"
    )
    
    db.add(new_payment)
    db.commit()
    db.refresh(new_payment)
    return new_payment
