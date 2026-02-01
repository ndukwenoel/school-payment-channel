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

from .auth import get_db, get_current_user, CheckRole

@router.post("/", response_model=schemas.Fee)
def create_fee(
    fee: schemas.FeeCreate, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if fee.amount <= 0:
        raise HTTPException(status_code=400, detail="Fee amount must be positive")
        
    # Verify student exists and belongs to the same school as the admin
    student = db.query(models.Student).filter(
        models.Student.id == fee.student_id,
        models.Student.school_id == current_user.school_id
    ).first()
    
    if not student:
         raise HTTPException(status_code=404, detail="Student not found in your school")

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
def create_bulk_fees(
    fee_data: schemas.FeeBulkCreate, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if fee_data.amount <= 0:
        raise HTTPException(status_code=400, detail="Fee amount must be positive")
        
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
        
        # Log notification
        if student.parent:
            log = models.NotificationLog(
                recipient_email=student.parent.email,
                subject=f"New Fee Assigned: {fee_data.title}",
                message=f"A new fee of {fee_data.amount} has been assigned to {student.full_name} due by {fee_data.due_date.strftime('%Y-%m-%d')}.",
                status="sent"
            )
            db.add(log)
            
        count += 1
    
    db.commit()
    return {"message": "Fees pushed successfully to parents", "count": count}

@router.get("/student/{student_id}", response_model=List[schemas.Fee])
def get_student_fees(
    student_id: int, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    student = db.query(models.Student).filter(models.Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
        
    # Parent can only see their own students
    if current_user.role == "parent" and student.parent_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied to this student's records")
        
    # Admins can only see students in their school
    if current_user.role in ["admin", "school_admin"] and student.school_id != current_user.school_id:
        raise HTTPException(status_code=403, detail="Access denied to students in other schools")

    fees = db.query(models.Fee).filter(models.Fee.student_id == student_id).all()
    
    # Issue 11: Overdue Status Transitions (Check on Read)
    now = datetime.now(timezone.utc)
    updated = False
    for fee in fees:
        # If pending/partial and past due date, mark overdue
        # Convert fee.due_date to naive or aware if needed. Assuming aware.
        due_date = fee.due_date.replace(tzinfo=timezone.utc) if fee.due_date.tzinfo is None else fee.due_date
        if fee.status in ["pending", "partial"] and now > due_date:
            fee.status = "overdue"
            updated = True
    
    if updated:
        db.commit()
        
    return fees

@router.post("/pay", response_model=schemas.Payment)
def pay_fee(
    payment: schemas.PaymentCreate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if payment.amount_paid <= 0:
        raise HTTPException(status_code=400, detail="Payment amount must be positive")

    fee = db.query(models.Fee).filter(models.Fee.id == payment.fee_id).first()
    if not fee:
        raise HTTPException(status_code=404, detail="Fee not found")
    
    # Ownership Check: Parent of student OR admin of the school
    is_parent = fee.student.parent_id == current_user.id
    is_admin = current_user.role in ["admin", "school_admin"] and fee.student.school_id == current_user.school_id
    
    if not (is_parent or is_admin):
        raise HTTPException(status_code=403, detail="Not authorized to pay this fee")

    # Calculate Total Paid so far
    total_paid = sum(p.amount_paid for p in fee.payments)
    
    # Calculate Net Amount Due (after discount)
    net_amount = fee.amount
    if fee.discount:
        if fee.discount.percentage > 0:
            net_amount -= (fee.amount * (fee.discount.percentage / 100))
        if fee.discount.flat_amount > 0:
            net_amount -= fee.discount.flat_amount
    
    remaining_balance = net_amount - total_paid
    
    if payment.amount_paid > remaining_balance + 0.01: # Small epsilon for float issues
        raise HTTPException(
            status_code=400, 
            detail=f"Overpayment not allowed. Remaining balance: {remaining_balance:.2f}"
        )
    
    new_total_paid = total_paid + payment.amount_paid
    
    # Update Status
    if new_total_paid >= net_amount - 0.01:
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
    # Log notification record
    log = models.NotificationLog(
        recipient_email=fee.student.parent.email,
        subject=f"Payment Received: {fee.title}",
        message=f"A payment of {payment.amount_paid:.2f} has been received for {fee.student.full_name}.",
        status="sent"
    )
    db.add(log)
    
    db.commit()
    db.refresh(new_payment)
    return new_payment
