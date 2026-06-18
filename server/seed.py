from server.database import SessionLocal
from server.models import User, School, Student, Invoice
from server.security import get_password_hash

def seed_db():
    db = SessionLocal()
    
    # Check if admin exists
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

    # Check if school exists
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
        
    # Create test student
    student = db.query(Student).first()
    if not student:
        print("Creating test student...")
        student = Student(
            school_id=school.id,
            full_name="John Doe",
            enrollment_number="STU-001",
            grade="10th Grade"
        )
        db.add(student)
        db.commit()
        db.refresh(student)

    print("Database seeded successfully! You can login with:")
    print("Email: admin@school.com")
    print("Password: password123")

    db.close()

if __name__ == "__main__":
    seed_db()
