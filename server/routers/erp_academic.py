from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from .. import database, models, schemas
from .auth import get_db, CheckRole

router = APIRouter(
    prefix="/erp/academic",
    tags=["ERP Academic"]
)

# --- ClassRoom Endpoints ---
@router.post("/classrooms", response_model=schemas.ClassRoom)
def create_classroom(
    room: schemas.ClassRoomCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if room.school_id != current_user.school_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized for this school")
    
    new_room = models.ClassRoom(**room.model_dump())
    db.add(new_room)
    db.commit()
    db.refresh(new_room)
    return new_room

@router.get("/classrooms", response_model=List[schemas.ClassRoom])
def get_classrooms(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher"]))
):
    return db.query(models.ClassRoom).filter(models.ClassRoom.school_id == current_user.school_id).all()

# --- Subject Endpoints ---
@router.post("/subjects", response_model=schemas.Subject)
def create_subject(
    subject: schemas.SubjectCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if subject.school_id != current_user.school_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    new_subject = models.Subject(**subject.model_dump())
    db.add(new_subject)
    db.commit()
    db.refresh(new_subject)
    return new_subject

@router.get("/subjects", response_model=List[schemas.Subject])
def get_subjects(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher"]))
):
    return db.query(models.Subject).filter(models.Subject.school_id == current_user.school_id).all()

# --- Attendance Endpoints ---
@router.post("/attendance", response_model=schemas.Attendance)
def mark_attendance(
    attendance: schemas.AttendanceCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher"]))
):
    if attendance.school_id != current_user.school_id:
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    new_record = models.Attendance(**attendance.model_dump())
    db.add(new_record)
    db.commit()
    db.refresh(new_record)
    return new_record

@router.get("/attendance/student/{student_id}", response_model=List[schemas.Attendance])
def get_student_attendance(
    student_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher", "parent"]))
):
    student = db.query(models.Student).filter(models.Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    if current_user.role == "parent" and student.parent_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized for this student")
    
    if current_user.role in ["school_admin", "teacher"] and student.school_id != current_user.school_id:
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    return db.query(models.Attendance).filter(models.Attendance.student_id == student_id).all()

# --- Grade Endpoints ---
@router.post("/grades", response_model=schemas.GradeRecord)
def record_grade(
    grade: schemas.GradeRecordCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher"]))
):
    if grade.school_id != current_user.school_id:
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    new_grade = models.GradeRecord(**grade.model_dump())
    db.add(new_grade)
    db.commit()
    db.refresh(new_grade)
    return new_grade

@router.get("/grades/student/{student_id}", response_model=List[schemas.GradeRecord])
def get_student_grades(
    student_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher", "parent"]))
):
    student = db.query(models.Student).filter(models.Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    if current_user.role == "parent" and student.parent_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized for this student")

    return db.query(models.GradeRecord).filter(models.GradeRecord.student_id == student_id).all()

@router.get("/report/term", response_model=dict)
def generate_term_report(
    class_id: int,
    term: str,
    academic_year: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher"]))
):
    # Verify authorization
    classroom = db.query(models.ClassRoom).filter(models.ClassRoom.id == class_id).first()
    if not classroom:
         raise HTTPException(status_code=404, detail="Classroom not found")
         
    if classroom.school_id != current_user.school_id:
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    # Fetch all students in the class
    students = db.query(models.Student).filter(models.Student.classroom_id == class_id).all()
    
    report_data = []
    
    for student in students:
        # Get grades for this term
        grades = db.query(models.GradeRecord).filter(
            models.GradeRecord.student_id == student.id,
            models.GradeRecord.term == term,
            models.GradeRecord.academic_year == academic_year
        ).all()
        
        if not grades:
            continue
            
        total_score = sum(g.score for g in grades)
        average = total_score / len(grades) if grades else 0
        
        subjects_data = [{"subject": g.subject_id, "score": g.score} for g in grades]
        
        report_data.append({
            "student_id": student.id,
            "student_name": student.full_name,
            "average": average,
            "total_score": total_score,
            "subjects": subjects_data
        })
    
    # Sort by average descending for ranking
    report_data.sort(key=lambda x: x["average"], reverse=True)
    
    # Assign rank
    for rank, data in enumerate(report_data, 1):
        data["rank"] = rank
        
    return {
        "classroom": classroom.name,
        "term": term,
        "academic_year": academic_year,
        "student_reports": report_data
    }
