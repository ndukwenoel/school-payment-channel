from server.database import SessionLocal
from server.models import (
    User, School, Student, Invoice, InvoiceLineItem, VirtualAccount,
    FeeTemplate, FeeTemplateLineItem, PostingRule, PaymentAttempt
)
from server.security import get_password_hash
from datetime import datetime, timezone, timedelta

def seed_db():
    db = SessionLocal()
    
    # 1. Users & School
    admin = db.query(User).filter(User.email == "admin@school.com").first()
    if not admin:
        print("Creating admin user...")
        admin = User(
            email="admin@school.com",
            hashed_password=get_password_hash("password123"),
            full_name="System Admin",
            role="admin"
        )
        db.add(admin)
        db.commit()
        db.refresh(admin)

    parent = db.query(User).filter(User.email == "parent@school.com").first()
    if not parent:
        print("Creating parent user...")
        parent = User(
            email="parent@school.com",
            hashed_password=get_password_hash("password123"),
            full_name="Jane Doe (Parent)",
            role="parent"
        )
        db.add(parent)
        db.commit()
        db.refresh(parent)

    school = db.query(School).first()
    if not school:
        print("Creating default school...")
        school = School(
            name="Greenwood High",
            admin_id=admin.id,
            subscription_plan="premium"
        )
        db.add(school)
        db.commit()
        db.refresh(school)
        
    # 2. Student & Virtual Account
    student = db.query(Student).filter(Student.enrollment_number == "STU-001").first()
    if not student:
        print("Creating test student...")
        student = Student(
            school_id=school.id,
            parent_id=parent.id,
            full_name="John Doe",
            enrollment_number="STU-001",
            grade="10th Grade"
        )
        db.add(student)
        db.commit()
        db.refresh(student)

    virtual_account = db.query(VirtualAccount).filter(VirtualAccount.student_id == student.id).first()
    if not virtual_account:
        print("Creating virtual account for student...")
        virtual_account = VirtualAccount(
            account_number="9988776655",
            account_name="Greenwood - John Doe",
            bank_name="Wema Bank",
            student_id=student.id,
            school_id=school.id
        )
        db.add(virtual_account)
        db.commit()

    # 3. Fee Templates
    fee_template = db.query(FeeTemplate).filter(FeeTemplate.name == "Term 1 Standard Fees").first()
    if not fee_template:
        print("Creating fee template...")
        fee_template = FeeTemplate(
            name="Term 1 Standard Fees",
            description="Default tuition and boarding for Term 1",
            school_id=school.id
        )
        db.add(fee_template)
        db.flush()
        db.add(FeeTemplateLineItem(template_id=fee_template.id, title="Tuition", amount=500.0))
        db.add(FeeTemplateLineItem(template_id=fee_template.id, title="Library Fee", amount=50.0))
        db.add(FeeTemplateLineItem(template_id=fee_template.id, title="Sports Fee", amount=100.0))
        db.commit()

    # 4. Invoices
    invoice = db.query(Invoice).filter(Invoice.student_id == student.id).first()
    if not invoice:
        print("Creating sample invoice...")
        invoice = Invoice(
            title="Term 1 Fees - John Doe",
            due_date=datetime.now(timezone.utc) + timedelta(days=30),
            student_id=student.id,
            school_id=school.id,
            status="pending"
        )
        db.add(invoice)
        db.flush()
        db.add(InvoiceLineItem(invoice_id=invoice.id, title="Tuition", amount=500.0))
        db.add(InvoiceLineItem(invoice_id=invoice.id, title="Library Fee", amount=50.0))
        db.add(InvoiceLineItem(invoice_id=invoice.id, title="Sports Fee", amount=100.0))
        db.commit()

    # 5. Posting Rules
    rule = db.query(PostingRule).first()
    if not rule:
        print("Creating default posting rules...")
        rules = [
            PostingRule(event_type="payment.received", provider="paystack", debit_account_name="Paystack Holding", credit_account_name="School Revenue", school_id=school.id),
            PostingRule(event_type="payment.received", provider="monnify", debit_account_name="Monnify Vault", credit_account_name="School Revenue", school_id=school.id),
            PostingRule(event_type="payment.exception", provider="manual_bank_transfer", debit_account_name="Main Bank Account", credit_account_name="Unreconciled Funds", school_id=school.id),
        ]
        db.add_all(rules)
        db.commit()

    print("Database seeded with Phase 2 & 3 Dummy Data!")
    print("Admin: admin@school.com / password123")
    print("Parent: parent@school.com / password123")
    db.close()

if __name__ == "__main__":
    seed_db()
