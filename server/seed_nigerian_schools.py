import random
from datetime import datetime, timezone, timedelta
from sqlalchemy import func
from server.database import SessionLocal, engine, Base
from server.models import (
    User, School, Student, ClassRoom, Subject,
    Attendance, GradeRecord, Invoice, InvoiceLineItem, VirtualAccount,
    FeeTemplate, FeeTemplateLineItem,
    CourseTest, TestResult, StaffProfile, Payroll, InventoryItem,
    Broadcast, AcademicResource,
    Role, Permission, RolePermission, AuditLog, LedgerAccount, LedgerTransaction, LedgerEntry, PostingRule
)
from server.security import get_password_hash

def seed_nigerian_data():
    db = SessionLocal()
    
    print("Seeding 2 Nigerian Primary Schools...")
    
    # 1. Create Schools
    school1_name = "Excel Academy Lagos"
    school2_name = "Heritage International School Abuja"
    
    school1 = db.query(School).filter(School.name == school1_name).first()
    if not school1:
        school1 = School(name=school1_name, address="14 Broad Street, Victoria Island, Lagos", contact_email="info@excelacademylagos.edu.ng")
        db.add(school1)
    
    school2 = db.query(School).filter(School.name == school2_name).first()
    if not school2:
        school2 = School(name=school2_name, address="22 Gana Street, Maitama, Abuja", contact_email="contact@heritageabuja.edu.ng")
        db.add(school2)
    
    db.commit()
    db.refresh(school1)
    db.refresh(school2)
    
    schools = [school1, school2]
    
    # Generate Subjects
    subjects_data = [
        ("Mathematics", "MTH101"),
        ("English Language", "ENG101"),
        ("Basic Science", "BSC101"),
        ("Social Studies", "SST101"),
        ("Civic Education", "CVE101"),
        ("Agricultural Science", "AGR101"),
    ]
    
    for sch in schools:
        for name, code in subjects_data:
            subj = db.query(Subject).filter(Subject.code == code, Subject.school_id == sch.id).first()
            if not subj:
                subj = Subject(name=name, code=code, school_id=sch.id)
                db.add(subj)
    db.commit()
    
    # Classrooms
    classrooms_data = [
        ("Primary 1", "A"), ("Primary 1", "B"),
        ("Primary 2", "A"), ("Primary 2", "B"),
        ("Primary 3", "A"),
        ("Primary 4", "A"),
        ("Primary 5", "A"), ("Primary 5", "B"),
        ("Primary 6", "A")
    ]
    for sch in schools:
        for name, section in classrooms_data:
            cr = db.query(ClassRoom).filter(ClassRoom.name == name, ClassRoom.section == section, ClassRoom.school_id == sch.id).first()
            if not cr:
                cr = ClassRoom(name=name, section=section, school_id=sch.id)
                db.add(cr)
    db.commit()

    # Staff (18 total, maybe 9 per school)
    nigerian_last_names = ["Adebayo", "Okafor", "Nwachukwu", "Ibrahim", "Abubakar", "Danladi", "Oluwaseun", "Eze", "Okoro", "Adeyemi", "Bello", "Chukwu", "Umar", "Olawale", "Nwosu", "Adekunle", "Oni", "Ogunleye", "Balogun", "Ojo"]
    nigerian_first_names = ["Chinedu", "Fatima", "Aminu", "Ngozi", "Aisha", "Emeka", "Olamide", "Zainab", "Musa", "Tolu", "Kemi", "Ifeanyi", "Binta", "Dayo", "Yusuf", "Chioma", "Mustapha", "Nnamdi", "Blessing", "Samuel"]

    staff_roles = [
        ("Head Teacher", 150000), ("Teacher", 70000), ("Teacher", 70000), 
        ("Teacher", 70000), ("Teacher", 70000), ("Teacher", 70000),
        ("Bursar", 100000), ("Cleaner", 30000), ("Security", 35000)
    ]
    
    print("Generating 18 Staff...")
    staff_count = 0
    for sch in schools:
        for role, salary in staff_roles:
            fname = random.choice(nigerian_first_names)
            lname = random.choice(nigerian_last_names)
            email = f"{fname.lower()}.{lname.lower()}{staff_count}@{sch.name.split()[0].lower()}.edu.ng"
            
            user = User(
                email=email,
                hashed_password=get_password_hash("password123"),
                full_name=f"{fname} {lname}",
                role="teacher" if role == "Teacher" else "admin" if role in ["Head Teacher", "Bursar"] else "staff",
                school_id=sch.id
            )
            db.add(user)
            db.flush()
            
            staff = StaffProfile(
                employee_id=f"EMP-{sch.id}-{staff_count+1}",
                designation=role,
                base_salary=salary,
                user_id=user.id,
                school_id=sch.id
            )
            db.add(staff)
            staff_count += 1
    db.commit()
    
    # Students (at least 130 randomly distributed)
    print("Generating 135 Students...")
    now = datetime.now(timezone.utc)
    
    for i in range(135):
        sch = random.choice(schools)
        cr_list = db.query(ClassRoom).filter(ClassRoom.school_id == sch.id).all()
        cr = random.choice(cr_list)
        
        fname = random.choice(nigerian_first_names)
        lname = random.choice(nigerian_last_names)
        
        # Parent
        parent_email = f"parent_{fname.lower()}.{lname.lower()}{i}@gmail.com"
        parent = User(
            email=parent_email,
            hashed_password=get_password_hash("password123"),
            full_name=f"Mr/Mrs {lname}",
            role="parent",
            school_id=sch.id
        )
        db.add(parent)
        db.flush()
        
        enroll_num = f"{sch.name[:3].upper()}-{2026}{i:03d}"
        
        # Determine tuition (30k - 50k)
        tuition = random.choice([30000, 35000, 40000, 45000, 50000])
        
        student = Student(
            school_id=sch.id,
            parent_id=parent.id,
            full_name=f"{fname} {lname}",
            enrollment_number=enroll_num,
            grade=cr.name,
            classroom_id=cr.id,
            date_of_birth=now - timedelta(days=random.randint(1800, 4000)), # 5-11 years old
            gender=random.choice(["Male", "Female"]),
            home_address=f"{random.randint(1, 150)} {random.choice(['Awolowo Way', 'Nnamdi Azikiwe Express', 'Allen Avenue', 'Ademola Adetokunbo'])}",
            emergency_contact_name=parent.full_name,
            emergency_contact_phone=f"080{random.randint(20000000, 99999999)}",
            blood_group=random.choice(["O+", "A+", "B+", "AB+", "O-"]),
            genotype=random.choice(["AA", "AS", "SS"]),
            admission_date=now - timedelta(days=random.randint(10, 1000))
        )
        db.add(student)
        db.flush()
        
        # Invoice for Tuition
        inv_title = f"Term 1 Tuition - {cr.name}"
        inv = Invoice(
            title=inv_title,
            due_date=now + timedelta(days=30),
            student_id=student.id,
            school_id=sch.id,
            status=random.choice(["pending", "paid", "partial"])
        )
        db.add(inv)
        db.flush()
        
        db.add(InvoiceLineItem(invoice_id=inv.id, title="Tuition Fee", amount=float(tuition)))
        db.add(InvoiceLineItem(invoice_id=inv.id, title="PTA Levy", amount=5000.0))
        
        # Virtual Account
        va = VirtualAccount(
            account_number=f"90{random.randint(10000000, 99999999)}",
            account_name=f"{sch.name[:10]} - {student.full_name}",
            bank_name=random.choice(["GTBank", "Zenith Bank", "Access Bank", "First Bank"]),
            student_id=student.id,
            school_id=sch.id
        )
        db.add(va)
        
    db.commit()
    print("Nigerian schools data generated successfully!")

if __name__ == "__main__":
    seed_nigerian_data()
