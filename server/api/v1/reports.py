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
def get_dashboard_summary(
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if not current_user.school_id:
         raise HTTPException(status_code=400, detail="User not assigned to a school")

    # Filter by user's school strictly
    student_query = db.query(models.Student).filter(models.Student.school_id == current_user.school_id)
    total_students = student_query.count()

    # Issue 13: Data Leakage Prevention
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

    # Total Revenue (sum of all payments for school's students)
    total_revenue = db.query(func.sum(models.Payment.amount_paid))\
        .join(models.Fee)\
        .join(models.Student)\
        .filter(models.Student.school_id == current_user.school_id)\
        .scalar() or 0.0

    return {
        "total_students": total_students,
        "total_revenue": total_revenue,
        "outstanding_fees": outstanding_fees,
        "total_fees_created": total_fees_created
    }
