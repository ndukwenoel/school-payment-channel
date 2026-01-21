from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from .. import database, models, schemas
from .auth import get_db, get_current_user
import csv
import codecs
from io import StringIO

router = APIRouter(
    prefix="/students",
    tags=["Students"]
)

@router.get("/", response_model=list[schemas.Student])
def read_students(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.school_id is None:
         raise HTTPException(status_code=400, detail="User does not belong to a school")
    
    students = db.query(models.Student).filter(models.Student.school_id == current_user.school_id).offset(skip).limit(limit).all()
    return students

@router.post("/", response_model=schemas.Student)
def create_student(student: schemas.StudentCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role not in ["admin", "school_admin"]:
        raise HTTPException(status_code=403, detail="Not authorized")
    if current_user.school_id is None:
         raise HTTPException(status_code=400, detail="User does not belong to a school")

    db_student = models.Student(**student.dict(), school_id=current_user.school_id)
    db.add(db_student)
    db.commit()
    db.refresh(db_student)
    return db_student

@router.post("/import")
async def import_students(file: UploadFile = File(...), db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role not in ["admin", "school_admin"]:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    if current_user.school_id is None:
         raise HTTPException(status_code=400, detail="User does not belong to a school")

    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="Invalid file type. Please upload a CSV.")

    # Read CSV
    content = await file.read()
    csv_reader = csv.DictReader(codecs.iterdecode(StringIO(content.decode("utf-8")), 'utf-8'))
    
    imported_count = 0
    errors = []
    
    for row in csv_reader:
        try:
            # Expected headers: enrollment_number, full_name, grade, parent_email
            enrollment_number = row.get("enrollment_number")
            full_name = row.get("full_name")
            grade = row.get("grade")
            parent_email = row.get("parent_email")
            
            if not enrollment_number or not full_name:
                continue

            # Find or create parent
            parent = db.query(models.User).filter(models.User.email == parent_email).first()
            if not parent:
                # Create a placeholder parent account? Or fail?
                # For MVP, let's create a pending parent account with default password "password123"
                # In real app, trigger invitation email.
                from ..security import get_password_hash
                parent = models.User(
                    email=parent_email, 
                    hashed_password=get_password_hash("password123"),
                    full_name="Parent of " + full_name,
                    role="parent",
                    school_id=current_user.school_id
                )
                db.add(parent)
                db.commit()
                db.refresh(parent)
            
            # Create student using model directly (bypassing schema validation for speed involves trade-offs)
            # Check if exists
            existing = db.query(models.Student).filter(models.Student.enrollment_number == enrollment_number, models.Student.school_id == current_user.school_id).first()
            if existing:
                errors.append(f"Student {enrollment_number} already exists")
                continue

            new_student = models.Student(
                enrollment_number=enrollment_number,
                full_name=full_name,
                grade=grade,
                parent_id=parent.id,
                school_id=current_user.school_id
            )
            db.add(new_student)
            imported_count += 1
        except Exception as e:
            errors.append(f"Error processing row {row}: {str(e)}")
    
    db.commit()
    
    return {"message": "Import processed", "imported_count": imported_count, "errors": errors}
