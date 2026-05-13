from sqlalchemy.orm import Session
from ..models import LedgerTransaction, LedgerEntry, LedgerAccount

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
