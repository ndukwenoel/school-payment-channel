from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ... import database, models, schemas
from .auth import get_db, get_current_user, CheckRole
from sqlalchemy import func

router = APIRouter(
    prefix="/reports",
    tags=["Reports"]
)

@router.get("/system-summary")
def get_system_summary(
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(CheckRole(["super_admin"]))
):
    total_schools = db.query(models.School).count()
    total_students = db.query(models.Student).count()
    total_users = db.query(models.User).count()
    
    # Per-school breakdown
    schools = db.query(models.School).all()
    school_details = []
    for school in schools:
        student_count = db.query(models.Student).filter(models.Student.school_id == school.id).count()
        staff_count = db.query(models.User).filter(models.User.school_id == school.id).count()
        school_details.append({
            "id": school.id,
            "name": school.name,
            "address": school.address,
            "contact_email": school.contact_email,
            "contact_phone": school.contact_phone,
            "logo_url": school.logo_url,
            "student_count": student_count,
            "staff_count": staff_count,
        })
    
    return {
        "total_schools": total_schools,
        "total_students": total_students,
        "total_users": total_users,
        "schools": school_details,
    }

@router.get("/executive-analytics")
def get_executive_analytics(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["super_admin", "admin", "school_admin"]))
):
    # For super_admin: system-wide. For school_admin: their school only.
    if current_user.role == "super_admin":
        invoices = db.query(models.Invoice).all()
        payrolls = db.query(models.Payroll).all()
        schools_count = db.query(models.School).count()
        platform_invoices = db.query(models.PlatformInvoice).filter(models.PlatformInvoice.status == "paid").all()
        students_count = db.query(models.Student).count()
        users_count = db.query(models.User).count()
    else:
        if not current_user.school_id:
            raise HTTPException(status_code=400, detail="User not assigned to a school")
        school_id = current_user.school_id
        invoices = db.query(models.Invoice).filter(models.Invoice.school_id == school_id).all()
        payrolls = db.query(models.Payroll).filter(models.Payroll.school_id == school_id).all()
        schools_count = 1
        platform_invoices = db.query(models.PlatformInvoice).filter(
            models.PlatformInvoice.school_id == school_id,
            models.PlatformInvoice.status == "paid"
        ).all()
        students_count = db.query(models.Student).filter(models.Student.school_id == school_id).count()
        users_count = db.query(models.User).filter(models.User.school_id == school_id).count()

    total_platform_volume = 0.0
    total_transactions = 0
    total_invoices_issued = len(invoices)
    total_payroll_processed = sum((p.net_pay or 0.0) for p in payrolls)
    saas_revenue_collected = sum(p.amount_due for p in platform_invoices)
    
    for inv in invoices:
        for p in inv.payment_attempts:
            if p.status == "success":
                total_platform_volume += p.amount
                total_transactions += 1

    return {
        "total_platform_volume": total_platform_volume,
        "total_transactions": total_transactions,
        "total_invoices_issued": total_invoices_issued,
        "total_payroll_processed": total_payroll_processed,
        "active_schools": schools_count,
        "saas_revenue_collected": saas_revenue_collected,
        "total_students": students_count,
        "total_users": users_count,
    }

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

    # Issue 13: Data Leakage Prevention (and Legacy Fee Fix)
    invoices = db.query(models.Invoice).filter(models.Invoice.school_id == current_user.school_id).all()
    
    total_fees_created = 0.0
    outstanding_fees = 0.0
    
    for inv in invoices:
        gross_amount = sum(item.amount for item in inv.line_items)
        total_fees_created += gross_amount
        
        # Calculate paid amount
        paid = sum(p.amount for p in inv.payment_attempts if p.status == "success")
        
        # Calculate net
        net = gross_amount
        if inv.discount:
            if inv.discount.percentage > 0:
                 net -= (gross_amount * (inv.discount.percentage / 100))
            if inv.discount.flat_amount > 0:
                 net -= inv.discount.flat_amount
        
        balance = net - paid
        if balance > 0:
            outstanding_fees += balance

    # Ledger-driven Total Revenue 
    school_revenue_account = db.query(models.LedgerAccount).filter(
        models.LedgerAccount.name == "School Revenue",
        models.LedgerAccount.school_id == current_user.school_id
    ).first()
    
    if school_revenue_account:
        total_revenue = db.query(func.sum(models.LedgerEntry.amount))\
            .filter(
                models.LedgerEntry.account_id == school_revenue_account.id,
                models.LedgerEntry.type == "credit"
            ).scalar() or 0.0
    else:
        total_revenue = 0.0

    return {
        "total_students": total_students,
        "total_revenue": total_revenue,
        "outstanding_invoices": outstanding_fees,
        "total_invoices_created": total_fees_created
    }
