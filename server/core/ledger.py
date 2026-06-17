from sqlalchemy.orm import Session
from ..models import LedgerTransaction, LedgerEntry, LedgerAccount, PostingRule

def record_transaction(db: Session, school_id: int, description: str, debit_account_name: str, credit_account_name: str, amount: float):
    """
    Records a financial transaction using double-entry ledger principles.
    Ensures that for every transaction, the debits and credits balance to zero.
    """
    # Fetch or create debit account (e.g., "Parent Wallet", "Cash")
    debit_account = db.query(LedgerAccount).filter(LedgerAccount.name == debit_account_name, LedgerAccount.school_id == school_id).first()
    if not debit_account:
        debit_account = LedgerAccount(name=debit_account_name, type="asset", school_id=school_id)
        db.add(debit_account)
        db.flush()
        
    # Fetch or create credit account (e.g., "Tuition Revenue")
    credit_account = db.query(LedgerAccount).filter(LedgerAccount.name == credit_account_name, LedgerAccount.school_id == school_id).first()
    if not credit_account:
        credit_account = LedgerAccount(name=credit_account_name, type="revenue", school_id=school_id)
        db.add(credit_account)
        db.flush()
        
    # Create the immutable transaction envelope
    transaction = LedgerTransaction(description=description, school_id=school_id)
    db.add(transaction)
    db.flush() # Flush to get transaction.id
    
    # Create balancing entries
    debit_entry = LedgerEntry(transaction_id=transaction.id, account_id=debit_account.id, amount=amount, type="debit")
    credit_entry = LedgerEntry(transaction_id=transaction.id, account_id=credit_account.id, amount=amount, type="credit")
    
    db.add(debit_entry)
    db.add(credit_entry)
    
    return transaction

def record_event_transaction(db: Session, school_id: int, description: str, event_type: str, provider: str, amount: float, fallback_debit: str = "Bank Account", fallback_credit: str = "School Revenue"):
    """
    Records a transaction by dynamically resolving the PostingRule.
    Falls back to provided defaults if no rule is found.
    """
    rule = db.query(PostingRule).filter(
        PostingRule.event_type == event_type,
        PostingRule.provider == provider,
        (PostingRule.school_id == school_id) | (PostingRule.school_id == None)
    ).first()
    
    if rule:
        debit_name = rule.debit_account_name
        credit_name = rule.credit_account_name
    else:
        debit_name = fallback_debit
        credit_name = fallback_credit
        
    return record_transaction(
        db=db,
        school_id=school_id,
        description=description,
        debit_account_name=debit_name,
        credit_account_name=credit_name,
        amount=amount
    )
