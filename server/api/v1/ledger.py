from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List

from ... import database, models, schemas
from .auth import get_db, CheckRole

router = APIRouter(
    prefix="/ledger",
    tags=["General Ledger & Bookkeeping"]
)

# --- Accounts ---

@router.get("/accounts", response_model=List[schemas.LedgerAccount])
def get_ledger_accounts(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin", "bursar"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    accounts = db.query(models.LedgerAccount).filter(
        models.LedgerAccount.school_id == current_user.school_id
    ).all()
    
    # Calculate balance for each account
    results = []
    for acc in accounts:
        debits = db.query(func.sum(models.LedgerEntry.amount)).filter(
            models.LedgerEntry.account_id == acc.id,
            models.LedgerEntry.type == "debit"
        ).scalar() or 0.0
        
        credits = db.query(func.sum(models.LedgerEntry.amount)).filter(
            models.LedgerEntry.account_id == acc.id,
            models.LedgerEntry.type == "credit"
        ).scalar() or 0.0
        
        # Assets and Expenses are debit normal; Liabilities, Equity, Revenue are credit normal
        if acc.type in ["asset", "expense"]:
            balance = debits - credits
        else:
            balance = credits - debits
            
        acc_dict = {
            "id": acc.id,
            "name": acc.name,
            "type": acc.type,
            "school_id": acc.school_id,
            "balance": balance
        }
        results.append(acc_dict)
        
    return results

@router.post("/accounts", response_model=schemas.LedgerAccount)
def create_ledger_account(
    account_data: schemas.LedgerAccountCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    existing = db.query(models.LedgerAccount).filter(
        models.LedgerAccount.name == account_data.name,
        models.LedgerAccount.school_id == current_user.school_id
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="Account with this name already exists")
        
    acc = models.LedgerAccount(
        name=account_data.name,
        type=account_data.type,
        school_id=current_user.school_id
    )
    db.add(acc)
    db.commit()
    db.refresh(acc)
    
    return {
        "id": acc.id,
        "name": acc.name,
        "type": acc.type,
        "school_id": acc.school_id,
        "balance": 0.0
    }

# --- Transactions (Journal) ---

@router.get("/transactions", response_model=List[schemas.LedgerTransaction])
def get_ledger_transactions(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin", "bursar"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    txns = db.query(models.LedgerTransaction).filter(
        models.LedgerTransaction.school_id == current_user.school_id
    ).order_by(models.LedgerTransaction.created_at.desc()).all()
    
    # Preload entries and accounts to construct full response
    results = []
    for t in txns:
        entries = []
        for e in t.entries:
            entries.append({
                "id": e.id,
                "transaction_id": e.transaction_id,
                "account_id": e.account_id,
                "amount": e.amount,
                "type": e.type,
                "account": {
                    "id": e.account.id,
                    "name": e.account.name,
                    "type": e.account.type,
                    "school_id": e.account.school_id
                }
            })
        
        results.append({
            "id": t.id,
            "description": t.description,
            "school_id": t.school_id,
            "created_at": t.created_at,
            "entries": entries
        })
        
    return results

# --- Posting Rules ---

@router.get("/rules", response_model=List[schemas.PostingRule])
def get_posting_rules(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    rules = db.query(models.PostingRule).filter(
        models.PostingRule.school_id == current_user.school_id
    ).all()
    
    return rules

@router.post("/rules", response_model=schemas.PostingRule)
def create_posting_rule(
    rule_data: schemas.PostingRuleCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    # Ensure accounts exist
    debit_acc = db.query(models.LedgerAccount).filter(
        models.LedgerAccount.name == rule_data.debit_account_name,
        models.LedgerAccount.school_id == current_user.school_id
    ).first()
    
    if not debit_acc:
        raise HTTPException(status_code=400, detail=f"Debit account '{rule_data.debit_account_name}' does not exist")
        
    credit_acc = db.query(models.LedgerAccount).filter(
        models.LedgerAccount.name == rule_data.credit_account_name,
        models.LedgerAccount.school_id == current_user.school_id
    ).first()
    
    if not credit_acc:
        raise HTTPException(status_code=400, detail=f"Credit account '{rule_data.credit_account_name}' does not exist")
        
    rule = models.PostingRule(
        event_type=rule_data.event_type,
        provider=rule_data.provider,
        debit_account_name=rule_data.debit_account_name,
        credit_account_name=rule_data.credit_account_name,
        school_id=current_user.school_id
    )
    
    db.add(rule)
    db.commit()
    db.refresh(rule)
    return rule
