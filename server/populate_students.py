import random
from datetime import datetime, timezone, timedelta
from server.database import SessionLocal
from server.models import Student

def populate_students():
    db = SessionLocal()
    students = db.query(Student).all()
    now = datetime.now(timezone.utc)
    
    count = 0
    for student in students:
        if not student.date_of_birth:
            dob = now - timedelta(days=random.randint(3650, 5475))
            student.date_of_birth = dob
            student.gender = random.choice(["Male", "Female"])
            student.home_address = f"{random.randint(1, 999)} {random.choice(['Main St', 'Oak Ave', 'Pine Ln', 'Maple Dr'])}, Cityville"
            last_name = student.full_name.split()[-1] if student.full_name else "Parent"
            student.emergency_contact_name = f"Mr/Mrs {last_name}"
            student.emergency_contact_phone = f"+234 {random.randint(7000000000, 9099999999)}"
            student.blood_group = random.choice(["O+", "A+", "B+", "AB+", "O-"])
            student.genotype = random.choice(["AA", "AS", "SS"])
            student.allergies = random.choice(["None", "Peanuts", "Dust", "None", "Pollen"])
            student.medical_conditions = random.choice(["None", "Asthma", "None", "None"])
            student.admission_date = now - timedelta(days=random.randint(100, 1000))
            count += 1
            
    db.commit()
    print(f"Successfully populated {count} students with rich profile data.")
    db.close()

if __name__ == "__main__":
    populate_students()
