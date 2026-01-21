from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from .. import database, models, schemas
from .auth import get_db, get_current_user
from sqlalchemy import func

router = APIRouter(
    prefix="/reports",
    tags=["Reports"]
)

@router.get("/summary", response_model=schemas.DashboardStats)
def get_dashboard_summary(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role not in ["admin", "school_admin"]:
         raise HTTPException(status_code=403, detail="Not authorized")

    # Filter by user's school if applicable
    student_query = db.query(models.Student)
    if current_user.school_id:
        student_query = student_query.filter(models.Student.school_id == current_user.school_id)
    
    total_students = student_query.count()

    # Fee logic needs to filter by fees belonging to students in this school
    # Complex query: Join Fee -> Student -> School
    fee_query = db.query(models.Fee).join(models.Student).filter(models.Student.school_id == current_user.school_id)
    
    total_fees_created = 0.0
    outstanding_fees = 0.0
    
    fees = fee_query.all()
    for fee in fees:
        total_fees_created += fee.amount
        
        # Calculate paid amount
        paid = sum(p.amount_paid for p in fee.payments)
        
        # Calculate net
        net = fee.amount
        if fee.discount:
            if fee.discount.percentage > 0:
                 net -= (fee.amount * (fee.discount.percentage / 100))
            if fee.discount.flat_amount > 0:
                 net -= fee.discount.flat_amount
        
        balance = net - paid
        if balance > 0:
            outstanding_fees += balance

    # Total Revenue (Payments made)
    # Join Payment -> Fee -> Student
    payment_query = db.query(models.Payment).join(models.Fee).join(models.Student).filter(models.Student.school_id == current_user.school_id)
    total_revenue = db.query(func.sum(models.Payment.amount_paid)).join(models.Fee).join(models.Student).filter(models.Student.school_id == current_user.school_id).scalar() or 0.0

    return {
        "total_students": total_students,
        "total_revenue": total_revenue,
        "outstanding_fees": outstanding_fees,
        "total_fees_created": total_fees_created
    }
