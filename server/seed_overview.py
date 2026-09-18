from datetime import datetime, timezone
from server.database import SessionLocal
from server.models.finance import LedgerAccount, LedgerTransaction, LedgerEntry, PaymentAttempt, Invoice
from server.models.school import School

def seed_overview_data():
    db = SessionLocal()
    school = db.query(School).first()
    
    # 1. School Revenue Account & Transaction
    acc_rev = db.query(LedgerAccount).filter_by(name="School Revenue", school_id=school.id).first()
    if not acc_rev:
        acc_rev = LedgerAccount(name="School Revenue", type="revenue", school_id=school.id)
        db.add(acc_rev)
        db.flush()
        
    acc_bank = db.query(LedgerAccount).filter_by(name="GTBank Operations", school_id=school.id).first()

    # Create a huge transaction for overview
    t1 = LedgerTransaction(description="Term 1 Accumulated Revenue", school_id=school.id, created_at=datetime.now(timezone.utc))
    db.add(t1)
    db.flush()
    db.add(LedgerEntry(transaction_id=t1.id, account_id=acc_bank.id, amount=12500000.0, type="debit"))
    db.add(LedgerEntry(transaction_id=t1.id, account_id=acc_rev.id, amount=12500000.0, type="credit"))

    # 2. Mock Successful Payment Attempts for breakdowns and settlements
    invoices = db.query(Invoice).filter(Invoice.school_id == school.id).limit(10).all()
    for inv in invoices:
        db.add(PaymentAttempt(
            invoice_id=inv.id,
            amount=45000.0,
            provider="paystack",
            status="success",
            transaction_id=f"PAYSTACK-REF-{inv.id}",
            school_id=school.id
        ))

    db.commit()
    db.close()
    print("Overview data successfully seeded!")

if __name__ == "__main__":
    seed_overview_data()
