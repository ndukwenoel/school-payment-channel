from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from ... import database, models, schemas
from .auth import get_db, CheckRole

router = APIRouter(
    prefix="/platform-billing",
    tags=["Platform Billing"]
)

@router.get("/", response_model=List[schemas.PlatformInvoice])
def get_platform_invoices(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["super_admin"]))
):
    return db.query(models.PlatformInvoice).order_by(models.PlatformInvoice.created_at.desc()).offset(skip).limit(limit).all()

@router.post("/", response_model=schemas.PlatformInvoice)
def create_platform_invoice(
    invoice: schemas.PlatformInvoiceCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["super_admin"]))
):
    new_invoice = models.PlatformInvoice(**invoice.model_dump())
    db.add(new_invoice)
    db.commit()
    db.refresh(new_invoice)
    
    # Audit log
    audit = models.AuditLog(
        user_id=current_user.id,
        action="CREATE",
        table_name="platform_invoices",
        record_id=str(new_invoice.id),
        new_values=f"Created invoice for school {invoice.school_id} amount {invoice.amount_due}"
    )
    db.add(audit)
    db.commit()
    
    return new_invoice

@router.patch("/{invoice_id}/pay", response_model=schemas.PlatformInvoice)
def mark_platform_invoice_paid(
    invoice_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["super_admin"]))
):
    invoice = db.query(models.PlatformInvoice).filter(models.PlatformInvoice.id == invoice_id).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
        
    invoice.status = "paid"
    
    # Audit log
    audit = models.AuditLog(
        user_id=current_user.id,
        action="UPDATE",
        table_name="platform_invoices",
        record_id=str(invoice_id),
        new_values="Marked as paid"
    )
    db.add(audit)
    db.commit()
    db.refresh(invoice)
    return invoice
