from datetime import datetime, timezone
from server.database import SessionLocal
from server.models.finance import LedgerAccount, LedgerTransaction, LedgerEntry
from server.models.school import School

def seed_ledgers():
    db = SessionLocal()
    school = db.query(School).first()
    
    # Ensure accounts exist
    acc_unreconciled = db.query(LedgerAccount).filter_by(name="Unreconciled Funds", school_id=school.id).first()
    if not acc_unreconciled:
        acc_unreconciled = LedgerAccount(name="Unreconciled Funds", type="liability", school_id=school.id)
        db.add(acc_unreconciled)
        
    acc_revenue = db.query(LedgerAccount).filter_by(name="Tuition Revenue", school_id=school.id).first()
    if not acc_revenue:
        acc_revenue = LedgerAccount(name="Tuition Revenue", type="revenue", school_id=school.id)
        db.add(acc_revenue)
        
    acc_bank = db.query(LedgerAccount).filter_by(name="GTBank Operations", school_id=school.id).first()
    if not acc_bank:
        acc_bank = LedgerAccount(name="GTBank Operations", type="asset", school_id=school.id)
        db.add(acc_bank)
        
    db.commit()

    if db.query(LedgerTransaction).filter_by(school_id=school.id).count() == 0:
        # 1. Normal Transaction
        t1 = LedgerTransaction(description="Term 1 Tuition Payment - John Doe", school_id=school.id, created_at=datetime.now(timezone.utc))
        db.add(t1)
        db.flush()
        db.add(LedgerEntry(transaction_id=t1.id, account_id=acc_bank.id, amount=150000.0, type="debit"))
        db.add(LedgerEntry(transaction_id=t1.id, account_id=acc_revenue.id, amount=150000.0, type="credit"))

        # 2. Exception Transaction (Unreconciled)
        t2 = LedgerTransaction(description="Unknown Bank Transfer ZEN-9901", school_id=school.id, created_at=datetime.now(timezone.utc))
        db.add(t2)
        db.flush()
        db.add(LedgerEntry(transaction_id=t2.id, account_id=acc_bank.id, amount=45000.0, type="debit"))
        db.add(LedgerEntry(transaction_id=t2.id, account_id=acc_unreconciled.id, amount=45000.0, type="credit"))

        db.commit()

    db.close()
    print("Ledger transactions seeded!")

if __name__ == "__main__":
    seed_ledgers()
