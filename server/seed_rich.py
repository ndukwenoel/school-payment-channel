import random
from datetime import datetime, timezone, timedelta
from server.database import SessionLocal
from server.models import (
    User, School, Student, ClassRoom, Subject,
    Attendance, GradeRecord, Invoice, InvoiceLineItem, VirtualAccount,
    FeeTemplate, FeeTemplateLineItem
)
from server.security import get_password_hash

def seed_rich_data():
    db = SessionLocal()
    
    # 1. School & Admin
    admin = db.query(User).filter(User.email == "admin@school.com").first()
    school = db.query(School).filter(School.name == "Greenwood High").first()
    
    if not school:
        admin = User(
            email="admin@school.com",
            hashed_password=get_password_hash("password123"),
            full_name="System Admin",
            role="admin"
        )
        db.add(admin)
        db.commit()
        db.refresh(admin)
        
        school = School(
            name="Greenwood High",
            admin_id=admin.id,
            subscription_plan="premium"
        )
        db.add(school)
        db.commit()
        db.refresh(school)
        
    print("School ensured:", school.name)

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
            role="parent"
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

    print("Rich database seed completed successfully.")
    print("New Parent login: richparent@school.com / password123")
    db.close()

if __name__ == "__main__":
    seed_rich_data()
