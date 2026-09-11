from server.database import SessionLocal
from server.models import User, School

db = SessionLocal()

schools = {s.id: s.name for s in db.query(School).all()}

print("=" * 80)
for sid, sname in schools.items():
    print(f"\n--- {sname} (ID: {sid}) ---")
    users = db.query(User).filter(User.school_id == sid).order_by(User.role).all()
    for role in ['admin', 'teacher', 'staff', 'parent']:
        role_users = [u for u in users if u.role == role]
        if role_users:
            print(f"  [{role.upper()}]")
            for u in role_users[:3]:  # Show up to 3 per role
                print(f"    Email: {u.email}  |  Name: {u.full_name}")
            if len(role_users) > 3:
                print(f"    ... and {len(role_users)-3} more {role}s")

# Check for users without school
no_school = db.query(User).filter(User.school_id == None).all()
if no_school:
    print(f"\n--- NO SCHOOL ASSIGNED ---")
    for u in no_school:
        print(f"  [{u.role.upper()}] Email: {u.email}  |  Name: {u.full_name}")

db.close()
