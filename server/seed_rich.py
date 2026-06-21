import random
from datetime import datetime, timezone, timedelta
from server.database import SessionLocal
from server.models import (
    User, School, Student, ClassRoom, Subject,
    Attendance, GradeRecord, Invoice, InvoiceLineItem, VirtualAccount,
    FeeTemplate, FeeTemplateLineItem,
    CourseTest, TestResult, StaffProfile, Payroll, InventoryItem,
    Broadcast, AcademicResource,
    Role, Permission, RolePermission, AuditLog, LedgerAccount, LedgerTransaction, LedgerEntry, PostingRule
)
from server.security import get_password_hash

def seed_rich_data():
    db = SessionLocal()
    
    # 1. School & Admin
    school = db.query(School).filter(School.name == "Greenwood High").first()
    if not school:
        school = School(name="Greenwood High")
        db.add(school)
        db.commit()
        db.refresh(school)
        
    admin = db.query(User).filter(User.email == "admin@school.com").first()
    if not admin:
        admin = User(
            email="admin@school.com",
            hashed_password=get_password_hash("password123"),
            full_name="System Admin",
            role="admin",
            school_id=school.id
        )
        db.add(admin)
        db.commit()
        db.refresh(admin)
        
    print("School ensured:", school.name)

    # 1.5 Core Data (RBAC, Ledger, PostingRules)
    print("Seeding Core Data (RBAC & Ledger)...")
    
    # RBAC
    permissions_data = ["can_create_fee", "can_view_reports", "can_edit_grades"]
    for p_name in permissions_data:
        p = db.query(Permission).filter(Permission.name == p_name).first()
        if not p:
            p = Permission(name=p_name)
            db.add(p)
    db.commit()

    roles_data = ["bursar", "principal", "teacher"]
    for r_name in roles_data:
        r = db.query(Role).filter(Role.name == r_name, Role.school_id == school.id).first()
        if not r:
            r = Role(name=r_name, school_id=school.id)
            db.add(r)
    db.commit()

    # Ledger Accounts
    accounts_data = [
        ("School Revenue", "revenue"),
        ("Cash in Bank", "asset"),
        ("Parent Wallet", "liability"),
        ("Salary Expense", "expense")
    ]
    for acc_name, acc_type in accounts_data:
        acc = db.query(LedgerAccount).filter(LedgerAccount.name == acc_name, LedgerAccount.school_id == school.id).first()
        if not acc:
            acc = LedgerAccount(name=acc_name, type=acc_type, school_id=school.id)
            db.add(acc)
    db.commit()

    # Posting Rules
    rules_data = [
        ("payment.received", "paystack", "Cash in Bank", "School Revenue"),
        ("payment.refund", "paystack", "School Revenue", "Cash in Bank")
    ]
    for event, provider, debit, credit in rules_data:
        pr = db.query(PostingRule).filter(PostingRule.event_type == event, PostingRule.provider == provider, PostingRule.school_id == school.id).first()
        if not pr:
            pr = PostingRule(event_type=event, provider=provider, debit_account_name=debit, credit_account_name=credit, school_id=school.id)
            db.add(pr)
    db.commit()


    # 2. Subjects
    subjects_data = [
        ("Mathematics", "MATH101"),
        ("English Language", "ENG101"),
        ("Biology", "BIO101"),
        ("Physics", "PHY101"),
        ("Chemistry", "CHE101"),
    ]
    subjects = []
    for name, code in subjects_data:
        subj = db.query(Subject).filter(Subject.code == code).first()
        if not subj:
            subj = Subject(name=name, code=code, school_id=school.id)
            db.add(subj)
            db.commit()
            db.refresh(subj)
        subjects.append(subj)
    
    # 3. ClassRooms
    classrooms_data = [
        ("Grade 10", "A"),
        ("Grade 10", "B"),
        ("Grade 11", "Science"),
        ("Grade 11", "Arts")
    ]
    classrooms = []
    for name, section in classrooms_data:
        cr = db.query(ClassRoom).filter(ClassRoom.name == name, ClassRoom.section == section).first()
        if not cr:
            cr = ClassRoom(name=name, section=section, school_id=school.id)
            db.add(cr)
            db.commit()
            db.refresh(cr)
        classrooms.append(cr)
        
    # 4. Create Parent
    parent_email = "richparent@school.com"
    parent = db.query(User).filter(User.email == parent_email).first()
    if not parent:
        parent = User(
            email=parent_email,
            hashed_password=get_password_hash("password123"),
            full_name="Rich Parent",
            role="parent",
            school_id=school.id
        )
        db.add(parent)
        db.commit()
        db.refresh(parent)

    # 5. Students & Accounts & Invoices & Grades & Attendance
    # Generate 15 students
    first_names = ["Alice", "Bob", "Charlie", "Diana", "Ethan", "Fiona", "George", "Hannah", "Ian", "Julia", "Kevin", "Liam", "Mia", "Noah", "Olivia"]
    last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson"]
    
    # Fee template
    fee_template = db.query(FeeTemplate).filter(FeeTemplate.name == "Standard Term Fees").first()
    if not fee_template:
        fee_template = FeeTemplate(
            name="Standard Term Fees",
            description="Default tuition and fees",
            school_id=school.id
        )
        db.add(fee_template)
        db.flush()
        db.add(FeeTemplateLineItem(template_id=fee_template.id, title="Tuition", amount=1500.0))
        db.add(FeeTemplateLineItem(template_id=fee_template.id, title="Library Fee", amount=100.0))
        db.add(FeeTemplateLineItem(template_id=fee_template.id, title="Sports Fee", amount=200.0))
        db.commit()
    
    print("Generating students, attendance, grades, invoices...")
    
    now = datetime.now(timezone.utc)
    for i in range(15):
        enroll_num = f"STU-R{1000+i}"
        student = db.query(Student).filter(Student.enrollment_number == enroll_num).first()
        if not student:
            classroom = random.choice(classrooms)
            student = Student(
                school_id=school.id,
                parent_id=parent.id,
                full_name=f"{first_names[i]} {last_names[i]}",
                enrollment_number=enroll_num,
                grade=classroom.name,
                classroom_id=classroom.id
            )
            db.add(student)
            db.commit()
            db.refresh(student)
            
            # Virtual Account
            va = VirtualAccount(
                account_number=f"200{random.randint(1000000, 9999999)}",
                account_name=f"Greenwood - {student.full_name}",
                bank_name="Wema Bank",
                student_id=student.id,
                school_id=school.id
            )
            db.add(va)
            
            # Attendance for past 5 days
            for d in range(5):
                status = random.choices(["present", "absent", "late"], weights=[0.8, 0.1, 0.1])[0]
                att = Attendance(
                    date=now - timedelta(days=d),
                    status=status,
                    student_id=student.id,
                    school_id=school.id
                )
                db.add(att)
                
            # Grade records (Term 1)
            for subj in subjects:
                gr = GradeRecord(
                    score=random.uniform(50.0, 99.0),
                    term="Term 1",
                    academic_year="2025/2026",
                    student_id=student.id,
                    subject_id=subj.id,
                    school_id=school.id
                )
                db.add(gr)
                
            # Invoices
            # One pending invoice
            inv_pending = Invoice(
                title=f"Term 1 Fees - {student.full_name}",
                due_date=now + timedelta(days=15),
                student_id=student.id,
                school_id=school.id,
                status="pending"
            )
            db.add(inv_pending)
            db.flush()
            db.add(InvoiceLineItem(invoice_id=inv_pending.id, title="Tuition", amount=1500.0))
            db.add(InvoiceLineItem(invoice_id=inv_pending.id, title="Library", amount=100.0))
            
            # One paid invoice
            inv_paid = Invoice(
                title=f"Registration Fee - {student.full_name}",
                due_date=now - timedelta(days=30),
                student_id=student.id,
                school_id=school.id,
                status="paid"
            )
            db.add(inv_paid)
            db.flush()
            db.add(InvoiceLineItem(invoice_id=inv_paid.id, title="Registration", amount=300.0))
            
            db.commit()

    print("Generating Staff, Payroll, Course Tests, Inventory, and Broadcasts...")
    
    # 6. Staff & Payroll
    staff_roles = [
        ("Mr. Anderson", "teacher_anderson@school.com", "Teacher", 4000.0),
        ("Mrs. Smith", "teacher_smith@school.com", "Teacher", 4200.0),
        ("Dr. Brown", "teacher_brown@school.com", "Senior Teacher", 5000.0),
        ("Mr. Green", "accountant@school.com", "Accountant", 4500.0),
    ]
    staff_profiles = []
    for i, (name, email, role, salary) in enumerate(staff_roles):
        user = db.query(User).filter(User.email == email).first()
        if not user:
            user = User(
                email=email,
                hashed_password=get_password_hash("password123"),
                full_name=name,
                role="teacher" if "Teacher" in role else "admin",
                school_id=school.id
            )
            db.add(user)
            db.flush()
        
        staff = db.query(StaffProfile).filter(StaffProfile.user_id == user.id).first()
        if not staff:
            staff = StaffProfile(
                employee_id=f"EMP-2026-{i+10}",
                designation=role,
                base_salary=salary,
                user_id=user.id,
                school_id=school.id
            )
            db.add(staff)
            db.flush()
            
            # Payroll for last month
            payroll = Payroll(
                month="May",
                year=now.year,
                base_salary=salary,
                bonuses=200.0 if "Senior" in role else 0.0,
                deductions=50.0,
                net_pay=salary + (200.0 if "Senior" in role else 0.0) - 50.0,
                staff_id=staff.id,
                school_id=school.id
            )
            db.add(payroll)
        staff_profiles.append(staff)

    # 7. Course Tests & Results
    students = db.query(Student).filter(Student.school_id == school.id).all()
    for classroom in classrooms:
        for subj in subjects[:2]: # Only for a couple subjects to save time
            ct = CourseTest(
                title=f"Mid-Term {subj.name}",
                test_type="exam",
                max_score=100.0,
                weight_percentage=40.0,
                term="Term 1",
                academic_year="2025/2026",
                date_administered=now - timedelta(days=10),
                subject_id=subj.id,
                classroom_id=classroom.id,
                school_id=school.id,
                created_by=admin.id
            )
            db.add(ct)
            db.flush()
            
            # Add results for students in this classroom
            class_students = [s for s in students if s.classroom_id == classroom.id]
            for s in class_students:
                score = random.uniform(40.0, 98.0)
                remarks = "Excellent" if score > 80 else "Needs improvement" if score < 50 else "Good"
                res = TestResult(
                    score=score,
                    remarks=remarks,
                    test_id=ct.id,
                    student_id=s.id,
                    school_id=school.id
                )
                db.add(res)
                
    # 8. Inventory Items
    inventory_data = [
        ("Whiteboard Markers (Box)", "Stationery", 50, 15.0),
        ("A4 Printing Paper (Ream)", "Stationery", 200, 25.0),
        ("Microscopes", "Lab Equipment", 10, 450.0),
        ("Laptops (Staff)", "Electronics", 25, 800.0),
    ]
    for name, cat, qty, price in inventory_data:
        item = InventoryItem(
            name=name,
            category=cat,
            quantity=qty,
            unit_price=price,
            school_id=school.id
        )
        db.add(item)
        
    # 9. Broadcasts & Academic Resources
    bcast1 = Broadcast(
        title="Welcome to the New Academic Year!",
        message="We are thrilled to welcome all students back to Greenwood High. Classes begin promptly.",
        type="newsletter",
        school_id=school.id
    )
    bcast2 = Broadcast(
        title="Upcoming PTA Meeting",
        message="Please be reminded of the general PTA meeting scheduled for this Friday.",
        type="event",
        school_id=school.id
    )
    db.add(bcast1)
    db.add(bcast2)
    
    res1 = AcademicResource(
        title="Grade 10 Mathematics Syllabus",
        file_url="https://example.com/syllabus.pdf",
        type="note",
        school_id=school.id,
        teacher_id=admin.id
    )
    db.add(res1)

    # 10. Ledger Accounts and Bookkeeping Core Data
    cash_acc = LedgerAccount(name="Cash at Bank", type="asset", school_id=school.id)
    revenue_acc = LedgerAccount(name="Tuition Revenue", type="revenue", school_id=school.id)
    receivables_acc = LedgerAccount(name="Accounts Receivable", type="asset", school_id=school.id)
    db.add_all([cash_acc, revenue_acc, receivables_acc])
    db.flush()

    trx = LedgerTransaction(description=f"Registration Fee Payment - Dummy", school_id=school.id)
    db.add(trx)
    db.flush()

    entry1 = LedgerEntry(transaction_id=trx.id, account_id=cash_acc.id, amount=300.0, type="debit")
    entry2 = LedgerEntry(transaction_id=trx.id, account_id=revenue_acc.id, amount=300.0, type="credit")
    db.add_all([entry1, entry2])

    db.commit()

    print("Rich database seed completed successfully.")
    print("New Parent login: richparent@school.com / password123")
    print("New Teacher login: teacher_smith@school.com / password123")
    db.close()

if __name__ == "__main__":
    seed_rich_data()
