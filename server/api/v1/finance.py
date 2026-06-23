from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ... import database, models, schemas
from .auth import get_db, get_current_user, CheckRole
from ...core.ledger import record_transaction

router = APIRouter(
    prefix="/finance",
    tags=["Finance Dashboard"]
)

@router.get("/pending-verifications", response_model=list[schemas.PaymentAttempt])
def get_pending_verifications(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    return db.query(models.PaymentAttempt).filter(
        models.PaymentAttempt.school_id == current_user.school_id,
        models.PaymentAttempt.status == "pending_verification"
    ).order_by(models.PaymentAttempt.payment_date.desc()).all()

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
    
    # Get breakdown by Invoice Title from PaymentAttempts
    breakdowns = []
    results = db.query(
        models.Invoice.title, 
        func.sum(models.PaymentAttempt.amount)
    ).join(models.PaymentAttempt).filter(
        models.PaymentAttempt.school_id == current_user.school_id,
        models.PaymentAttempt.status.in_(["success", "settled"])
    ).group_by(models.Invoice.title).all()
    
    for title, amount in results:
        breakdowns.append(schemas.RevenueBreakdown(category=title, amount=amount or 0.0))
    
    return schemas.RevenueReportResponse(total_revenue=total_revenue, breakdowns=breakdowns)

@router.get("/expected-settlements", response_model=schemas.ExpectedSettlementResponse)
def get_expected_settlements(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    # Find all successful payment attempts that are not internal wallet transfers (Pending Settlement)
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
        
    # Find settled amounts (Actual Settlement)
    settled_attempts = db.query(models.PaymentAttempt).filter(
        models.PaymentAttempt.school_id == current_user.school_id,
        models.PaymentAttempt.status == "settled",
        models.PaymentAttempt.provider.in_(["paystack", "flutterwave", "stripe"])
    ).all()
    
    total_settled = sum(a.amount for a in settled_attempts)
    
    return schemas.ExpectedSettlementResponse(
        total_expected=total_expected, 
        total_settled=total_settled, 
        providers=providers
    )

import csv
from io import StringIO
from fastapi import UploadFile, File

@router.post("/bank-statement/upload")
async def upload_bank_statement(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="Only CSV files are allowed")
        
    content = await file.read()
    decoded = content.decode('utf-8')
    csv_reader = csv.DictReader(StringIO(decoded))
    
    required_fields = ["Date", "Description", "Amount"]
    if not all(field in csv_reader.fieldnames for field in required_fields):
        raise HTTPException(
            status_code=400, 
            detail=f"CSV must contain the following columns: {', '.join(required_fields)}"
        )
        
    exception_count = 0
    total_amount = 0.0
    
    from ...core.ledger import record_event_transaction
    
    for row in csv_reader:
        try:
            amount = float(row.get("Amount", 0))
        except ValueError:
            continue
            
        if amount <= 0:
            continue # Only process incoming deposits
            
        description = row.get("Description", "")
        
        # Dump to manual review exceptions queue
        record_event_transaction(
            db=db,
            school_id=current_user.school_id,
            description=f"Manual Bank Deposit: {description}",
            event_type="payment.exception",
            provider="manual_bank_transfer",
            amount=amount,
            fallback_debit="Bank Account",
            fallback_credit="Unreconciled Funds"
        )
        exception_count += 1
        total_amount += amount
        
    db.commit()
    
    return {
        "message": "Bank statement processed",
        "processed_deposits": exception_count,
        "total_amount": total_amount,
        "exceptions_flagged": exception_count
    }

from typing import List

@router.get("/posting-rules", response_model=List[schemas.PostingRule])
def get_posting_rules(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
    return db.query(models.PostingRule).filter(models.PostingRule.school_id == current_user.school_id).all()

@router.post("/posting-rules", response_model=schemas.PostingRule)
def create_posting_rule(
    rule_data: schemas.PostingRuleCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
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

@router.post("/send-reminders")
def send_secure_reminders(
    req: schemas.ReminderRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")

    from datetime import datetime, timezone
    
    count = 0
    prefix = f"[{req.type.upper()}] "

    if req.target == "all_parents":
        # Send a general broadcast to all parents
        if not req.custom_message:
            raise HTTPException(status_code=400, detail="custom_message is required for 'all_parents' target")
            
        parents = db.query(models.User).filter(
            models.User.school_id == current_user.school_id,
            models.User.role == "parent"
        ).all()
        
        for parent in parents:
            log = models.NotificationLog(
                recipient_email=parent.email,
                subject="SCHOOL BROADCAST",
                message=f"{prefix}{req.custom_message}",
                status="sent",
                school_id=current_user.school_id
            )
            db.add(log)
            count += 1
            
    else:
        # Overdue invoices logic
        now = datetime.now(timezone.utc)
        overdue_invoices = db.query(models.Invoice).filter(
            models.Invoice.school_id == current_user.school_id,
            models.Invoice.status.in_(["pending", "partial", "overdue"]),
            models.Invoice.due_date < now
        ).all()

        for inv in overdue_invoices:
            student = inv.student
            if not student or not student.parent:
                continue
                
            total_due = sum(item.amount for item in inv.line_items)
            total_paid = sum(p.amount for p in inv.payment_attempts if p.status == "success")
            outstanding = total_due - total_paid
            
            if outstanding <= 0:
                continue

            # Check for virtual account
            va = db.query(models.VirtualAccount).filter(models.VirtualAccount.student_id == student.id).first()
            va_text = f"transfer directly to your ward's dedicated Virtual Account: {va.account_number} ({va.bank_name})" if va else "transfer to the school's bank account via the portal"

            if req.custom_message:
                msg_body = req.custom_message
            else:
                msg_body = f"Hello {student.parent.full_name}, this is a friendly reminder from the school. {student.full_name} has an overdue balance of NGN {outstanding:.2f} for {inv.title}. Please log in to your secure School Portal to view details, or {va_text}. Thank you."
            
            msg = f"{prefix}{msg_body}"

            log = models.NotificationLog(
                recipient_email=student.parent.email,
                subject=f"OVERDUE NOTICE: {inv.title}",
                message=msg,
                status="sent",
                school_id=current_user.school_id
            )
            db.add(log)
            inv.status = "overdue"
            count += 1
        
        
    db.commit()
    return {"status": "success", "messages_sent": count}

@router.get("/transactions")
def get_transactions(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    txns = db.query(models.LedgerTransaction).filter(
        models.LedgerTransaction.school_id == current_user.school_id
    ).order_by(models.LedgerTransaction.created_at.desc()).offset(skip).limit(limit).all()
    
    result = []
    for t in txns:
        entries = []
        for e in t.entries:
            entries.append({
                "account": e.account.name if e.account else "Unknown",
                "amount": e.amount,
                "type": e.type
            })
        result.append({
            "id": t.id,
            "description": t.description,
            "created_at": t.created_at,
            "entries": entries
        })
        
    return result

@router.post("/webhooks/payment")
def handle_payment_webhook(
    payload: schemas.WebhookPayload,
    db: Session = Depends(get_db)
):
    from ...core.ledger import record_event_transaction
    
    if payload.status != "success":
        return {"status": "ignored"}
        
    ref = payload.reference
    amount = payload.amount
    
    # 1. Check if it's a Payment Bundle
    if ref.startswith("BNDL-"):
        bundle = db.query(models.PaymentBundle).filter(models.PaymentBundle.reference == ref).first()
        if bundle and bundle.status != "paid":
            bundle.status = "paid"
            for item in bundle.items:
                inv = item.invoice
                inv.status = "paid"
                # Create PaymentAttempt
                attempt = models.PaymentAttempt(
                    invoice_id=inv.id,
                    amount=item.amount_allocated,
                    provider=payload.provider,
                    status="success",
                    transaction_id=ref,
                    school_id=bundle.school_id
                )
                db.add(attempt)
                
                # Ledger entry
                record_event_transaction(
                    db=db,
                    school_id=bundle.school_id,
                    description=f"Bundle Payment {ref} - Invoice {inv.title}",
                    event_type="payment.received",
                    provider=payload.provider,
                    amount=item.amount_allocated,
                    fallback_debit="Bank Account",
                    fallback_credit="School Revenue"
                )
            db.commit()
            return {"status": "success", "message": "Bundle reconciled"}

    # 2. Check if it's a Virtual Account transfer
    va = db.query(models.VirtualAccount).filter(models.VirtualAccount.account_number == ref).first()
    if va:
        school_id = va.school_id
        # Find oldest pending invoice for this student
        oldest_invoice = db.query(models.Invoice).filter(
            models.Invoice.student_id == va.student_id,
            models.Invoice.status.in_(["pending", "partial", "overdue"])
        ).order_by(models.Invoice.due_date.asc()).first()
        
        if oldest_invoice:
            # For simulation, we assume full payment of whatever amount is sent
            oldest_invoice.status = "paid"
            attempt = models.PaymentAttempt(
                invoice_id=oldest_invoice.id,
                amount=amount,
                provider=payload.provider,
                status="success",
                transaction_id=f"VA-TRANS-{ref}",
                school_id=school_id
            )
            db.add(attempt)
            record_event_transaction(
                db=db,
                school_id=school_id,
                description=f"Virtual Account Transfer {ref} - Invoice {oldest_invoice.title}",
                event_type="payment.received",
                provider=payload.provider,
                amount=amount,
                fallback_debit="Bank Account",
                fallback_credit="School Revenue"
            )
            db.commit()
            return {"status": "success", "message": "Virtual Account transfer reconciled to invoice"}
        else:
            # Student has no pending invoices, credit their Parent Wallet or Unreconciled
            record_event_transaction(
                db=db,
                school_id=school_id,
                description=f"Virtual Account Transfer {ref} (No pending invoices)",
                event_type="payment.wallet_credit",
                provider=payload.provider,
                amount=amount,
                fallback_debit="Bank Account",
                fallback_credit="Parent Wallet"
            )
            db.commit()
            return {"status": "success", "message": "Virtual Account transfer credited to wallet"}
            
    # 3. Fallback: Unreconciled Funds
    # For this simulation, we'll assume a global admin or we can just ignore.
    return {"status": "unreconciled", "message": "Reference not matched"}

@router.post("/run-late-fees")
def run_late_fees(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    school = db.query(models.School).filter(models.School.id == current_user.school_id).first()
    if not school or not school.enable_late_fees:
        return {"status": "skipped", "message": "Late fees are disabled for this school"}
        
    now = datetime.now(timezone.utc)
    
    # Find all invoices that are pending/partial and not yet applied late fee
    invoices = db.query(models.Invoice).filter(
        models.Invoice.school_id == current_user.school_id,
        models.Invoice.status.in_(["pending", "partial", "overdue"]),
        models.Invoice.late_fee_applied == False
    ).all()
    
    count = 0
    total_late_fees = 0.0
    
    for inv in invoices:
        grace_period = timedelta(days=school.late_fee_grace_period_days)
        if now > (inv.due_date + grace_period):
            total_due = sum(item.amount for item in inv.line_items)
            total_paid = sum(p.amount for p in inv.payment_attempts if p.status == "success")
            outstanding = total_due - total_paid
            
            if outstanding > 0:
                fee_amount = round(outstanding * (school.late_fee_percentage / 100.0), 2)
                
                # Add line item
                late_fee_item = models.InvoiceLineItem(
                    invoice_id=inv.id,
                    description=f"Late Fee ({school.late_fee_percentage}%)",
                    amount=fee_amount
                )
                db.add(late_fee_item)
                
                inv.late_fee_applied = True
                inv.status = "overdue"
                count += 1
                total_late_fees += fee_amount
                
    db.commit()
    return {
        "status": "success", 
        "invoices_updated": count, 
        "total_late_fees_added": total_late_fees
    }

@router.post("/expenses", response_model=schemas.Expense)
def log_expense(
    expense_data: schemas.ExpenseCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    expense = models.Expense(
        title=expense_data.title,
        amount=expense_data.amount,
        category=expense_data.category,
        payment_date=expense_data.payment_date,
        school_id=current_user.school_id,
        recorded_by_id=current_user.id
    )
    db.add(expense)
    
    # Ledger Entry: Debit "School Expenses", Credit "Bank Account"
    from ...core.ledger import record_transaction
    
    debit_account = "Payroll Expense" if expense.category == "Payroll" else "School Expenses"
    
    record_transaction(
        db=db,
        school_id=current_user.school_id,
        description=f"Expense Logged: {expense.title}",
        debit_account_name=debit_account,
        credit_account_name="Bank Account",
        amount=expense.amount
    )
    
    db.commit()
    db.refresh(expense)
    return expense

@router.get("/expenses", response_model=List[schemas.Expense])
def get_expenses(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    return db.query(models.Expense).filter(
        models.Expense.school_id == current_user.school_id
    ).order_by(models.Expense.payment_date.desc()).all()

@router.get("/analytics/executive")
def get_executive_analytics(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "finance_admin", "principal"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    from sqlalchemy import func
    
    # Total Revenue (sum of successful payments)
    total_revenue = db.query(func.sum(models.PaymentAttempt.amount)).filter(
        models.PaymentAttempt.school_id == current_user.school_id,
        models.PaymentAttempt.status == "success"
    ).scalar() or 0.0
    
    # Total Expenses
    total_expenses = db.query(func.sum(models.Expense.amount)).filter(
        models.Expense.school_id == current_user.school_id
    ).scalar() or 0.0
    
    net_profit = total_revenue - total_expenses
    
    # Invoice stats
    total_invoices = db.query(models.Invoice).filter(models.Invoice.school_id == current_user.school_id).count()
    paid_invoices = db.query(models.Invoice).filter(models.Invoice.school_id == current_user.school_id, models.Invoice.status == "paid").count()
    
    # Recent Expenses
    recent_expenses = db.query(models.Expense).filter(
        models.Expense.school_id == current_user.school_id
    ).order_by(models.Expense.payment_date.desc()).limit(5).all()
    
    return {
        "total_revenue": total_revenue,
        "total_expenses": total_expenses,
        "net_profit": net_profit,
        "total_invoices": total_invoices,
        "paid_invoices": paid_invoices,
        "unpaid_invoices": total_invoices - paid_invoices,
        "recent_expenses": [
            {
                "title": e.title,
                "amount": e.amount,
                "category": e.category,
                "date": e.payment_date.isoformat()
            } for e in recent_expenses
        ]
    }

