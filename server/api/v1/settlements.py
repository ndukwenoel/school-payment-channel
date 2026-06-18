import csv
from io import StringIO
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from ... import database, models, schemas
from .auth import get_db, get_current_user, CheckRole
from ...core.ledger import record_transaction

router = APIRouter(
    prefix="/settlements",
    tags=["Settlements"]
)

@router.post("/upload")
async def upload_settlement_csv(
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
    
    # Required columns in the CSV
    # Transaction Reference, Amount, Processing Fee, Settlement Amount
    required_fields = ["Transaction Reference", "Processing Fee", "Settlement Amount"]
    if not all(field in csv_reader.fieldnames for field in required_fields):
        raise HTTPException(
            status_code=400, 
            detail=f"CSV must contain the following columns: {', '.join(required_fields)}"
        )
        
    processed_count = 0
    total_fee = 0.0
    total_settled = 0.0
    not_found_count = 0
    
    for row in csv_reader:
        reference = row.get("Transaction Reference")
        try:
            fee = float(row.get("Processing Fee", 0))
            settled_amount = float(row.get("Settlement Amount", 0))
        except ValueError:
            continue # Skip invalid rows
            
        # Find matching successful payment attempt
        attempt = db.query(models.PaymentAttempt).filter(
            models.PaymentAttempt.transaction_id == reference,
            models.PaymentAttempt.school_id == current_user.school_id,
            models.PaymentAttempt.status == "success"
        ).first()
        
        if attempt:
            # Mark as settled
            attempt.status = "settled"
            
            # Post ledger transaction for this settlement
            desc = f"Settlement for [REF:{reference}]"
            
            # 1. Debit Bank Account for the Settled Amount
            record_transaction(
                db=db,
                school_id=current_user.school_id,
                description=f"{desc} - Bank Deposit",
                debit_account_name="Bank Account",
                credit_account_name="Provider Receivables", # Assuming Provider Receivables was credited or we offset it
                amount=settled_amount
            )
            
            # 2. Debit Processing Fees
            if fee > 0:
                record_transaction(
                    db=db,
                    school_id=current_user.school_id,
                    description=f"{desc} - Processing Fee",
                    debit_account_name="Processing Fees",
                    credit_account_name="Provider Receivables",
                    amount=fee
                )
                
            processed_count += 1
            total_fee += fee
            total_settled += settled_amount
        else:
            not_found_count += 1
            
    db.commit()
    
    return {
        "message": "Settlement file processed successfully",
        "processed": processed_count,
        "not_found_or_already_settled": not_found_count,
        "total_fee_recorded": total_fee,
        "total_settled_recorded": total_settled
    }
