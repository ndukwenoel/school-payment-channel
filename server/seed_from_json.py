import json
from datetime import datetime
import os
from sqlalchemy.orm import Session
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

def seed_db_from_json():
    print("Loading JSON data...")
    json_path = os.path.join(os.path.dirname(__file__), 'nigerian_schools_mock_api.json')
    with open(json_path, 'r') as f:
        data = json.load(f)

    db = SessionLocal()
    
    print("Clearing existing data and syncing schema safely...")
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    # Predefined Subjects
    subject_names = [
        ("Mathematics", "MTH101"),
        ("English Language", "ENG101"),
        ("Basic Science", "BSC101"),
        ("Social Studies", "SST101"),
        ("Civic Education", "CVE101"),
        ("Agricultural Science", "AGR101"),
        ("Computer Studies", "CMP101"),
        ("Christian Religious Studies", "CRS101"),
        ("Islamic Religious Studies", "IRS101"),
        ("Yoruba", "YOR101"),
        ("Igbo", "IGB101"),
        ("Hausa", "HAU101")
    ]
    
    print(f"Seeding {len(data['schools'])} Schools and their associated entities...")
    for school_data in data['schools']:
        # 1. Create School
        school = School(
            name=school_data["name"],
            address=school_data["address"],
            contact_email=school_data["contact_email"]
        )
        db.add(school)
        db.commit()
        db.refresh(school)
        
        # 2. Create Subjects for this school
        subj_map = {}
        for name, code in subject_names:
            s = Subject(name=name, code=code, school_id=school.id)
            db.add(s)
            db.commit()
            db.refresh(s)
            subj_map[name] = s.id
            
        # 3. Create Classrooms
        class_map = {}
        classes_sections = []
        for s in school_data.get("students", []):
            cs = s["class"] # "Primary 4 B"
            if cs not in classes_sections:
                classes_sections.append(cs)
                
        for cs in classes_sections:
            parts = cs.rsplit(" ", 1)
            c_name = parts[0]
            c_sec = parts[1] if len(parts) > 1 else ""
            cr = ClassRoom(name=c_name, section=c_sec, school_id=school.id)
            db.add(cr)
            db.commit()
            db.refresh(cr)
            class_map[cs] = cr.id

        # 4. Create Staff
        for staff in school_data.get("staff", []):
            user = User(
                email=staff["email"],
                hashed_password=get_password_hash("password123"),
                full_name=staff["name"],
                role="teacher" if "Teacher" in staff["role"] else "admin" if "Head" in staff["role"] or "Bursar" in staff["role"] else "staff",
                school_id=school.id
            )
            db.add(user)
            db.commit()
            db.refresh(user)
            
            profile = StaffProfile(
                employee_id=staff["employee_id"],
                designation=staff["role"],
                base_salary=float(staff["salary"]),
                user_id=user.id,
                school_id=school.id
            )
            db.add(profile)
            
        db.commit()

        # 5. Create Students
        for s_data in school_data.get("students", []):
            # Parent
            parent_email = s_data["parent_info"]["email"]
            parent = db.query(User).filter(User.email == parent_email).first()
            if not parent:
                parent = User(
                    email=parent_email,
                    hashed_password=get_password_hash("password123"),
                    full_name=s_data["parent_info"]["father_name"] + " & " + s_data["parent_info"]["mother_name"],
                    role="parent",
                    school_id=school.id
                )
                db.add(parent)
                db.commit()
                db.refresh(parent)
                
            student = Student(
                enrollment_number=s_data["enrollment_number"],
                full_name=s_data["full_name"],
                grade=s_data["class"].rsplit(" ", 1)[0],
                date_of_birth=datetime.strptime(s_data["date_of_birth"], "%Y-%m-%d"),
                gender=s_data["gender"],
                home_address=s_data["address"],
                emergency_contact_name=parent.full_name,
                emergency_contact_phone=s_data["parent_info"]["primary_contact_phone"],
                blood_group=s_data["blood_group"],
                genotype=s_data["genotype"],
                allergies=s_data["allergies"],
                medical_conditions=s_data["medical_conditions"],
                admission_date=datetime.strptime(s_data["admission_date"], "%Y-%m-%d"),
                status="active" if s_data.get("enrollment_status", "Active") == "Active" else "suspended",
                parent_id=parent.id,
                school_id=school.id,
                classroom_id=class_map[s_data["class"]]
            )
            db.add(student)
            db.commit()
            db.refresh(student)
            
            # Virtual Account
            v_data = s_data["virtual_account"]
            va = VirtualAccount(
                account_number=v_data["account_number"],
                account_name=v_data["account_name"],
                bank_name=v_data["bank_name"],
                student_id=student.id,
                classroom_id=student.classroom_id,
                school_id=school.id
            )
            db.add(va)
            
            # Attendance
            # Batch add to avoid too many commits
            att_objects = []
            for a_data in s_data.get("attendance", []):
                att_objects.append(
                    Attendance(
                        date=datetime.strptime(a_data["date"], "%Y-%m-%d"),
                        status=a_data["status"].lower(),
                        remarks=a_data["remark"],
                        student_id=student.id,
                        classroom_id=student.classroom_id,
                        school_id=school.id
                    )
                )
            db.bulk_save_objects(att_objects)
            
            # GradeRecords
            grade_objects = []
            for g_data in s_data.get("academic_performance", []):
                s_id = subj_map.get(g_data["subject"])
                if s_id:
                    grade_objects.append(
                        GradeRecord(
                            score=float(g_data["total"]),
                            term=g_data["term"],
                            academic_year="2025/2026",
                            student_id=student.id,
                            subject_id=s_id,
                            school_id=school.id
                        )
                    )
            db.bulk_save_objects(grade_objects)
            
            # Invoices
            for i_data in s_data.get("billing", []):
                inv = Invoice(
                    title=i_data["title"],
                    due_date=datetime.strptime(i_data["due_date"], "%Y-%m-%d"),
                    status=i_data["status"].lower(),
                    student_id=student.id,
                    school_id=school.id
                )
                db.add(inv)
                db.commit()
                db.refresh(inv)
                
                line_objects = []
                for li in i_data.get("line_items", []):
                    line_objects.append(
                        InvoiceLineItem(
                            invoice_id=inv.id,
                            title=li["description"],
                            amount=float(li["amount"])
                        )
                    )
                db.bulk_save_objects(line_objects)
                
            db.commit()

    print("Finished seeding database from JSON successfully!")

if __name__ == "__main__":
    seed_db_from_json()
