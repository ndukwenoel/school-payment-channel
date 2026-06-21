from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from ... import database, models, schemas
from .auth import get_db, get_current_user
import csv
import codecs
from io import StringIO

from .auth import get_db, get_current_user, CheckRole

router = APIRouter(
    prefix="/students",
    tags=["Students"]
)

@router.get("/", response_model=list[schemas.Student])
def read_students(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(get_current_user)
):
    if current_user.school_id is None:
         raise HTTPException(status_code=400, detail="User does not belong to a school")
    
    students = db.query(models.Student).filter(models.Student.school_id == current_user.school_id).offset(skip).limit(limit).all()
    
    result = []
    for s in students:
        s_dict = s.__dict__.copy()
        if s.classroom:
            s_dict["classroom_name"] = s.classroom.name
        result.append(s_dict)
    return result

@router.get("/{student_id}", response_model=schemas.Student)
def get_student(
    student_id: int, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(get_current_user)
):
    if current_user.school_id is None:
         raise HTTPException(status_code=400, detail="User does not belong to a school")
         
    student = db.query(models.Student).filter(models.Student.id == student_id, models.Student.school_id == current_user.school_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
        
    s_dict = student.__dict__.copy()
    if student.classroom:
        s_dict["classroom_name"] = student.classroom.name
    return s_dict

@router.patch("/{student_id}", response_model=schemas.Student)
def update_student(
    student_id: int,
    updates: schemas.StudentUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if current_user.school_id is None:
         raise HTTPException(status_code=400, detail="User does not belong to a school")
         
    student = db.query(models.Student).filter(models.Student.id == student_id, models.Student.school_id == current_user.school_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
        
    if updates.full_name is not None:
        student.full_name = updates.full_name
    if updates.grade is not None:
        student.grade = updates.grade
    if updates.classroom_id is not None:
        # verify classroom exists
        room = db.query(models.ClassRoom).filter(models.ClassRoom.id == updates.classroom_id, models.ClassRoom.school_id == current_user.school_id).first()
        if not room:
            raise HTTPException(status_code=400, detail="Invalid classroom_id")
        student.classroom_id = updates.classroom_id

    db.commit()
    db.refresh(student)
    
    s_dict = student.__dict__.copy()
    if student.classroom:
        s_dict["classroom_name"] = student.classroom.name
    return s_dict

@router.post("/admin", response_model=schemas.Student)
def create_admin_student(
    student_in: schemas.StudentCreateAdmin,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if current_user.school_id is None:
         raise HTTPException(status_code=400, detail="User does not belong to a school")

    existing = db.query(models.Student).filter(
        models.Student.enrollment_number == student_in.enrollment_number,
        models.Student.school_id == current_user.school_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Enrollment number already exists in this school")

    # Get or create parent
    parent = db.query(models.User).filter(models.User.email == student_in.parent_email).first()
    if not parent:
        from ..security import get_password_hash
        parent = models.User(
            email=student_in.parent_email, 
            hashed_password=get_password_hash("password123"),
            full_name="Parent of " + student_in.full_name,
            role="parent",
            school_id=current_user.school_id
        )
        db.add(parent)
        db.commit()
        db.refresh(parent)
        
    # Verify classroom
    if student_in.classroom_id:
        room = db.query(models.ClassRoom).filter(models.ClassRoom.id == student_in.classroom_id, models.ClassRoom.school_id == current_user.school_id).first()
        if not room:
            raise HTTPException(status_code=400, detail="Invalid classroom_id")

    db_student = models.Student(
        enrollment_number=student_in.enrollment_number,
        full_name=student_in.full_name,
        grade=student_in.grade,
        parent_id=parent.id,
        classroom_id=student_in.classroom_id,
        school_id=current_user.school_id
    )
    db.add(db_student)
    db.commit()
    db.refresh(db_student)
    
    s_dict = db_student.__dict__.copy()
    if db_student.classroom:
        s_dict["classroom_name"] = db_student.classroom.name
    return s_dict

@router.post("/", response_model=schemas.Student)
def create_student(
    student: schemas.StudentCreate, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if current_user.school_id is None:
         raise HTTPException(status_code=400, detail="User does not belong to a school")

    # Issue 7: Unique enrollment number within school
    existing = db.query(models.Student).filter(
        models.Student.enrollment_number == student.enrollment_number,
        models.Student.school_id == current_user.school_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Enrollment number already exists in this school")

    db_student = models.Student(**student.dict(), school_id=current_user.school_id)
    db.add(db_student)
    db.commit()
    db.refresh(db_student)
    
    from ...events import BaseEvent, EventDispatcher
    event = BaseEvent(
        event_type="StudentEnrolled",
        school_id=db_student.school_id,
        payload={
            "student_id": db_student.id,
            "enrollment_number": db_student.enrollment_number,
            "grade": db_student.grade,
            "parent_id": db_student.parent_id
        }
    )
    EventDispatcher.publish(event)
    
    return db_student

@router.post("/import")
async def import_students(
    file: UploadFile = File(...), 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if current_user.school_id is None:
         raise HTTPException(status_code=400, detail="User does not belong to a school")

    if not file.filename.lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Invalid file type. Please upload a CSV.")

    # Read CSV
    content = await file.read()
    try:
        decoded_content = content.decode("utf-8")
    except UnicodeDecodeError:
        try:
            decoded_content = content.decode("latin-1")
        except UnicodeDecodeError:
            raise HTTPException(status_code=400, detail="Could not decode CSV file. Use UTF-8.")
            
    csv_reader = csv.DictReader(StringIO(decoded_content))
    
    imported_count = 0
    errors = []
    
    successfully_imported_students = []
    # Issue 8: Atomic Import (using transaction)
    with db.begin_nested(): # Start a sub-transaction
        for i, row in enumerate(csv_reader):
            try:
                # Issue 9: Row Sanitization (strip whitespace from keys and values)
                sanitized_row = {k.strip() if k else k: v.strip() if v else v for k, v in row.items()}
                
                enrollment_number = sanitized_row.get("enrollment_number")
                full_name = sanitized_row.get("full_name")
                grade = sanitized_row.get("grade")
                parent_email = sanitized_row.get("parent_email")
                
                if not enrollment_number or not full_name:
                    errors.append(f"Row {i+1}: Missing required fields (enrollment/name)")
                    continue

                # Find or create parent
                parent = db.query(models.User).filter(models.User.email == parent_email).first()
                if not parent:
                    from ..security import get_password_hash
                    parent = models.User(
                        email=parent_email, 
                        hashed_password=get_password_hash("password123"),
                        full_name="Parent of " + full_name,
                        role="parent",
                        school_id=current_user.school_id
                    )
                    db.add(parent)
                    db.flush() # Flush to get parent.id without committing
                
                # Unique Check
                existing = db.query(models.Student).filter(
                    models.Student.enrollment_number == enrollment_number, 
                    models.Student.school_id == current_user.school_id
                ).first()
                
                if existing:
                    errors.append(f"Row {i+1}: Student {enrollment_number} already exists")
                    continue

                new_student = models.Student(
                    enrollment_number=enrollment_number,
                    full_name=full_name,
                    grade=grade,
                    parent_id=parent.id,
                    school_id=current_user.school_id
                )
                db.add(new_student)
                db.flush() # Flush to populate new_student.id
                successfully_imported_students.append(new_student)
                imported_count += 1
            except Exception as e:
                errors.append(f"Row {i+1}: Error - {str(e)}")

    db.commit()
    
    # Dispatch events for imported students
    if successfully_imported_students:
        from ...events import BaseEvent, EventDispatcher
        for s in successfully_imported_students:
            event = BaseEvent(
                event_type="StudentEnrolled",
                school_id=s.school_id,
                payload={
                    "student_id": s.id,
                    "enrollment_number": s.enrollment_number,
                    "grade": s.grade,
                    "parent_id": s.parent_id
                }
            )
            EventDispatcher.publish(event)
            
    return {"message": "Import processed", "imported_count": imported_count, "errors": errors}

@router.post("/promote")
def promote_students(
    promotion_data: schemas.StudentBulkPromote,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")
        
    students = db.query(models.Student).filter(
        models.Student.grade == promotion_data.current_grade,
        models.Student.school_id == current_user.school_id
    ).all()
    
    if not students:
        return {"message": "No students found in the specified grade", "count": 0}
        
    promoted_count = 0
    from ...events import BaseEvent, EventDispatcher
    
    for student in students:
        old_grade = student.grade
        student.grade = promotion_data.new_grade
        promoted_count += 1
        
        event = BaseEvent(
            event_type="StudentPromoted",
            school_id=student.school_id,
            payload={
                "student_id": student.id,
                "old_grade": old_grade,
                "new_grade": student.grade
            }
        )
        EventDispatcher.publish(event)
        
    db.commit()
    
    return {"message": f"Successfully promoted {promoted_count} students", "count": promoted_count}

