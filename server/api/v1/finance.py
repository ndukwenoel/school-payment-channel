from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ... import database, models, schemas
from .auth import get_db, get_current_user, CheckRole
from ...core.ledger import record_transaction

router = APIRouter(
    prefix="/finance",
    tags=["Finance Dashboard"]
)

@router.get("/exceptions")
def get_reconciliation_exceptions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    # Find the Unreconciled Funds account
    unreconciled_account = db.query(models.LedgerAccount).filter(
        models.LedgerAccount.name == "Unreconciled Funds",
        models.LedgerAccount.school_id == current_user.school_id
    ).first()
    
    if not unreconciled_account:
        return []
        
    # Find all transactions that credit this account (meaning they are exceptions)
    exceptions = db.query(models.LedgerTransaction).join(models.LedgerEntry).filter(
        models.LedgerEntry.account_id == unreconciled_account.id,
        models.LedgerEntry.type == "credit",
        models.LedgerTransaction.school_id == current_user.school_id
    ).order_by(models.LedgerTransaction.created_at.desc()).all()
    
    # Format the response
    results = []
    for txn in exceptions:
        amount = next((e.amount for e in txn.entries if e.account_id == unreconciled_account.id and e.type == "credit"), 0)
        # Check if already resolved (i.e. another transaction debited this account with the same reference)
        # For simplicity, we just return all exceptions. A more robust system would calculate the net balance per reference.
        results.append({
            "id": txn.id,
            "description": txn.description,
            "amount": amount,
            "created_at": txn.created_at
        })
        
    return results

from pydantic import BaseModel
class ResolveAction(BaseModel):
    action: str # 'refund' or 'credit_wallet'
    
@router.post("/resolve/{transaction_id}")
def resolve_exception(
    transaction_id: int,
    action_data: ResolveAction,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    txn = db.query(models.LedgerTransaction).filter(
        models.LedgerTransaction.id == transaction_id,
        models.LedgerTransaction.school_id == current_user.school_id
    ).first()
    
    if not txn:
        raise HTTPException(status_code=404, detail="Exception transaction not found")
        
    # Find the amount
    unreconciled_account = db.query(models.LedgerAccount).filter(
        models.LedgerAccount.name == "Unreconciled Funds",
        models.LedgerAccount.school_id == current_user.school_id
    ).first()
    
    if not unreconciled_account:
        raise HTTPException(status_code=400, detail="No unreconciled account setup")
        
    amount = next((e.amount for e in txn.entries if e.account_id == unreconciled_account.id and e.type == "credit"), 0)
    if amount <= 0:
        raise HTTPException(status_code=400, detail="No exception amount found for this transaction")
        
    # Check if already resolved
    resolution_desc = f"Resolution for [REF:EXC-{transaction_id}]"
    existing_res = db.query(models.LedgerTransaction).filter(
        models.LedgerTransaction.description == resolution_desc,
        models.LedgerTransaction.school_id == current_user.school_id
    ).first()
    
    if existing_res:
        raise HTTPException(status_code=400, detail="This exception is already resolved")
        
    if action_data.action == "refund":
        credit_acc = "Bank Account"
    elif action_data.action == "credit_wallet":
        credit_acc = "Parent Wallet"
    else:
        raise HTTPException(status_code=400, detail="Invalid action")
        
    # Debit Unreconciled Funds, Credit Bank/Parent Wallet
    record_transaction(
        db=db,
        school_id=current_user.school_id,
        description=resolution_desc,
        debit_account_name="Unreconciled Funds",
        credit_account_name=credit_acc,
        amount=amount
    )
    
    db.commit()
    return {"status": "success", "message": f"Exception resolved via {action_data.action}"}

from datetime import datetime, timezone, timedelta
from sqlalchemy import func

@router.get("/aging-report", response_model=schemas.AgingReportResponse)
def get_aging_report(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    now = datetime.now(timezone.utc)
    invoices = db.query(models.Invoice).filter(
        models.Invoice.school_id == current_user.school_id,
        models.Invoice.status.in_(["pending", "partial", "overdue"]),
        models.Invoice.due_date < now
    ).all()
    
    buckets = {
        "0-30 days": {"total": 0.0, "ids": []},
        "31-60 days": {"total": 0.0, "ids": []},
        "61-90 days": {"total": 0.0, "ids": []},
        "90+ days": {"total": 0.0, "ids": []}
    }
    
    total_overdue = 0.0
    
    for inv in invoices:
        days_late = (now - inv.due_date).days
        total_due = sum(item.amount for item in inv.line_items)
        total_paid = sum(p.amount for p in inv.payment_attempts if p.status == "success")
        outstanding = total_due - total_paid
        
        if outstanding <= 0:
            continue
            
        total_overdue += outstanding
        
        if days_late <= 30:
            bucket = "0-30 days"
        elif days_late <= 60:
            bucket = "31-60 days"
        elif days_late <= 90:
            bucket = "61-90 days"
        else:
            bucket = "90+ days"
            
        buckets[bucket]["total"] += outstanding
        buckets[bucket]["ids"].append(inv.id)
        
    response_buckets = []
    for k, v in buckets.items():
        if v["total"] > 0:
            response_buckets.append(schemas.AgingBucket(bucket=k, total_amount=v["total"], invoice_ids=v["ids"]))
            
    return schemas.AgingReportResponse(total_overdue=total_overdue, buckets=response_buckets)

@router.get("/revenue-report", response_model=schemas.RevenueReportResponse)
def get_revenue_report(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    revenue_account = db.query(models.LedgerAccount).filter(
        models.LedgerAccount.name == "School Revenue",
        models.LedgerAccount.school_id == current_user.school_id
    ).first()
    
    if not revenue_account:
        return schemas.RevenueReportResponse(total_revenue=0.0)
        
    # Aggregate all credits to School Revenue
    total_revenue = db.query(func.sum(models.LedgerEntry.amount)).filter(
        models.LedgerEntry.account_id == revenue_account.id,
        models.LedgerEntry.type == "credit"
    ).scalar() or 0.0
    
    return schemas.RevenueReportResponse(total_revenue=total_revenue)

@router.get("/expected-settlements", response_model=schemas.ExpectedSettlementResponse)
def get_expected_settlements(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    # Find all successful payment attempts that are not internal wallet transfers
    attempts = db.query(models.PaymentAttempt).filter(
        models.PaymentAttempt.school_id == current_user.school_id,
        models.PaymentAttempt.status == "success",
        models.PaymentAttempt.provider.in_(["paystack", "flutterwave", "stripe"])
    ).all()
    
    total_expected = 0.0
    providers = {}
    
    for att in attempts:
        total_expected += att.amount
        providers[att.provider] = providers.get(att.provider, 0.0) + att.amount
        
    # Note: In a real system, we would subtract settlements that have already been reconciled from bank deposits.
    
    return schemas.ExpectedSettlementResponse(total_expected=total_expected, providers=providers)

