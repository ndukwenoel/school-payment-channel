from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models import StaffProfile, User, School, Payroll
from database import engine

Session = sessionmaker(bind=engine)
session = Session()

# Assuming school_id = 1 for the admin
school = session.query(School).first()
if not school:
    school = School(name="Demo School", contact_email="demo@school.com")
    session.add(school)
    session.commit()
    session.refresh(school)

# Check if we have an admin user
admin = session.query(User).filter(User.role == "admin").first()
if not admin:
    print("No admin user found. Creating one...")
    admin = User(email="admin@school.com", hashed_password="hashed_pwd", full_name="System Admin", role="admin", school_id=school.id)
    session.add(admin)
    session.commit()
    session.refresh(admin)

staff_count = session.query(StaffProfile).count()
if staff_count == 0:
    print("Adding mock staff members...")
    
    # 1
    u1 = User(email="teacher1@demo.com", hashed_password="pwd", full_name="Sarah O'Connor", role="teacher", school_id=school.id)
    session.add(u1)
    session.commit()
    session.refresh(u1)
    
    s1 = StaffProfile(employee_id="EMP-001", designation="Senior Teacher", base_salary=150000.0, user_id=u1.id, school_id=school.id)
    session.add(s1)
    
    # 2
    u2 = User(email="teacher2@demo.com", hashed_password="pwd", full_name="John Doe", role="teacher", school_id=school.id)
    session.add(u2)
    session.commit()
    session.refresh(u2)
    
    s2 = StaffProfile(employee_id="EMP-002", designation="Junior Teacher", base_salary=80000.0, user_id=u2.id, school_id=school.id)
    session.add(s2)
    
    # 3
    u3 = User(email="accountant@demo.com", hashed_password="pwd", full_name="Jane Smith", role="teacher", school_id=school.id)
    session.add(u3)
    session.commit()
    session.refresh(u3)
    
    s3 = StaffProfile(employee_id="EMP-003", designation="Accountant", base_salary=120000.0, user_id=u3.id, school_id=school.id)
    session.add(s3)
    
    session.commit()
    print("Added 3 staff members.")

print("Staff:", session.query(StaffProfile).count())
print("Payroll:", session.query(Payroll).count())
session.close()
