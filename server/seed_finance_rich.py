import json
import random
from datetime import datetime, timezone, timedelta
from server.database import SessionLocal
from server.models.finance import PaymentAttempt, Expense, PaymentPlanRequest, PostingRule, UnmatchedPayment
from server.models.school import School
from server.models.user import User
from server.models.finance import Invoice

def seed_finance_rich():
    db = SessionLocal()
    
    print("Fetching School...")
    school = db.query(School).first()
    if not school:
        print("No school found, exiting.")
        return
        
    print("Updating School Settings...")
    school.enable_late_fees = True
    school.late_fee_percentage = 5.0
    school.allowed_installment_options = "2,3,4,6"
    
    print("Seeding Posting Rules...")
    if db.query(PostingRule).count() == 0:
        rules = [
            PostingRule(event_type="payment.received", provider="bank_transfer", debit_account_name="GTBank Operations", credit_account_name="Tuition Revenue", school_id=school.id),
            PostingRule(event_type="payment.received", provider="paystack", debit_account_name="Paystack Settlement", credit_account_name="General Revenue", school_id=school.id),
            PostingRule(event_type="payment.refund", provider="all", debit_account_name="Refunds Payable", credit_account_name="GTBank Operations", school_id=school.id),
        ]
        db.add_all(rules)
    
    print("Seeding Expenses...")
    if db.query(Expense).count() == 0:
        admin_user = db.query(User).filter(User.role == 'school_admin', User.school_id == school.id).first()
        admin_id = admin_user.id if admin_user else 1
        expenses = [
            Expense(title="Generator Diesel - August", amount=150000.0, category="Utilities", school_id=school.id, recorded_by_id=admin_id, payment_date=datetime.now(timezone.utc) - timedelta(days=5)),
            Expense(title="Staff Salaries - August", amount=2500000.0, category="Payroll", school_id=school.id, recorded_by_id=admin_id, payment_date=datetime.now(timezone.utc) - timedelta(days=2)),
            Expense(title="Internet Subscription", amount=45000.0, category="Utilities", school_id=school.id, recorded_by_id=admin_id, payment_date=datetime.now(timezone.utc) - timedelta(days=15)),
            Expense(title="Whiteboard Markers & Stationery", amount=12000.0, category="Supplies", school_id=school.id, recorded_by_id=admin_id, payment_date=datetime.now(timezone.utc) - timedelta(days=1)),
        ]
        db.add_all(expenses)

    print("Fetching Invoices...")
    pending_invoices = db.query(Invoice).filter(Invoice.school_id == school.id, Invoice.status == 'pending').limit(15).all()
    
    if pending_invoices:
        print("Seeding Payment Attempts (Verifications)...")
        for i in range(5):
            inv = pending_invoices[i]
            attempt = PaymentAttempt(
                invoice_id=inv.id,
                amount=sum(item.amount for item in inv.line_items) if inv.line_items else 50000.0,
                provider="manual_transfer",
                status="pending_verification",
                transaction_id=f"GTB-REF-{random.randint(100000, 999999)}",
                receipt_url="https://fake.url/receipt_upload.png",
                school_id=school.id,
                payment_date=datetime.now(timezone.utc) - timedelta(hours=random.randint(1, 48))
            )
            db.add(attempt)
            
        print("Seeding Payment Plan Requests...")
        parents = db.query(User).filter(User.role == 'parent').limit(5).all()
        for i in range(5, 10):
            inv = pending_invoices[i]
            parent = parents[i % len(parents)] if parents else None
            total_amt = sum(item.amount for item in inv.line_items) if inv.line_items else 50000.0
            
            proposed = [
                {"due_date": (datetime.now(timezone.utc) + timedelta(days=30)).isoformat(), "amount": total_amt / 3},
                {"due_date": (datetime.now(timezone.utc) + timedelta(days=60)).isoformat(), "amount": total_amt / 3},
                {"due_date": (datetime.now(timezone.utc) + timedelta(days=90)).isoformat(), "amount": total_amt / 3}
            ]
            
            plan_req = PaymentPlanRequest(
                invoice_id=inv.id,
                parent_id=parent.id if parent else 1,
                proposed_plan=json.dumps(proposed),
                reason="Multiple kids in school, requesting 3-part split.",
                status="pending",
                school_id=school.id,
                created_at=datetime.now(timezone.utc) - timedelta(hours=random.randint(1, 24))
            )
            db.add(plan_req)

    print("Seeding Unmatched Payments...")
    if db.query(UnmatchedPayment).count() == 0:
        unmatched = [
            UnmatchedPayment(amount=45000.0, bank_name="Zenith Bank", account_number="101****456", transaction_ref="ZEN-88901", narration="SCH FEES FROM MR OBI", school_id=school.id),
            UnmatchedPayment(amount=150000.0, bank_name="UBA", account_number="203****890", transaction_ref="UBA-99231", narration="TRANSFER FROM OLUWASEUN FOR TERM 1", school_id=school.id)
        ]
        db.add_all(unmatched)

    db.commit()
    db.close()
    print("Rich finance mock data successfully seeded!")

if __name__ == "__main__":
    seed_finance_rich()
