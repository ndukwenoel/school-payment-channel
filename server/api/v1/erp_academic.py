from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from ... import database, models, schemas
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


# =============================================================================
# CourseTest Endpoints
# =============================================================================

@router.post("/tests", response_model=schemas.CourseTest, summary="Create a course test")
def create_course_test(
    test: schemas.CourseTestCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher"]))
):
    if test.school_id != current_user.school_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    new_test = models.CourseTest(**test.model_dump(), created_by=current_user.id)
    db.add(new_test)
    db.commit()
    db.refresh(new_test)
    return new_test


@router.get("/tests", response_model=List[schemas.CourseTest], summary="List course tests")
def get_course_tests(
    classroom_id: int = None,
    subject_id: int = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher"]))
):
    query = db.query(models.CourseTest).filter(
        models.CourseTest.school_id == current_user.school_id
    )
    if classroom_id:
        query = query.filter(models.CourseTest.classroom_id == classroom_id)
    if subject_id:
        query = query.filter(models.CourseTest.subject_id == subject_id)
    return query.order_by(models.CourseTest.id.desc()).all()


@router.get("/tests/{test_id}", response_model=schemas.CourseTest, summary="Get a single course test")
def get_course_test(
    test_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher"]))
):
    test = db.query(models.CourseTest).filter(models.CourseTest.id == test_id).first()
    if not test:
        raise HTTPException(status_code=404, detail="Course test not found")
    if test.school_id != current_user.school_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized for this school")
    return test


@router.delete("/tests/{test_id}", summary="Delete a course test")
def delete_course_test(
    test_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    test = db.query(models.CourseTest).filter(models.CourseTest.id == test_id).first()
    if not test:
        raise HTTPException(status_code=404, detail="Course test not found")
    if test.school_id != current_user.school_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    # Remove associated results first
    db.query(models.TestResult).filter(models.TestResult.test_id == test_id).delete()
    db.delete(test)
    db.commit()
    return {"message": f"Course test {test_id} deleted successfully"}


# =============================================================================
# TestResult Endpoints
# =============================================================================

@router.post("/tests/{test_id}/results", response_model=schemas.TestResult, summary="Record a single test result")
def record_test_result(
    test_id: int,
    result: schemas.TestResultCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher"]))
):
    test = db.query(models.CourseTest).filter(models.CourseTest.id == test_id).first()
    if not test:
        raise HTTPException(status_code=404, detail="Course test not found")
    if test.school_id != current_user.school_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized for this school")
    if result.score > test.max_score:
        raise HTTPException(status_code=400, detail=f"Score {result.score} exceeds max score {test.max_score}")

    # Upsert: if result already exists, update it
    existing = db.query(models.TestResult).filter(
        models.TestResult.test_id == test_id,
        models.TestResult.student_id == result.student_id
    ).first()

    if existing:
        existing.score = result.score
        existing.remarks = result.remarks
        db.commit()
        db.refresh(existing)
        return existing

    new_result = models.TestResult(
        score=result.score,
        remarks=result.remarks,
        test_id=test_id,
        student_id=result.student_id,
        school_id=test.school_id
    )
    db.add(new_result)
    db.commit()
    db.refresh(new_result)
    return new_result


@router.post("/tests/{test_id}/results/bulk", summary="Bulk record results for a whole class")
def bulk_record_test_results(
    test_id: int,
    payload: schemas.BulkTestResultCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher"]))
):
    test = db.query(models.CourseTest).filter(models.CourseTest.id == test_id).first()
    if not test:
        raise HTTPException(status_code=404, detail="Course test not found")
    if test.school_id != current_user.school_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    saved_count = 0
    errors = []

    for item in payload.results:
        if item.score > test.max_score:
            errors.append(f"Student {item.student_id}: Score {item.score} exceeds max {test.max_score}")
            continue

        existing = db.query(models.TestResult).filter(
            models.TestResult.test_id == test_id,
            models.TestResult.student_id == item.student_id
        ).first()

        if existing:
            existing.score = item.score
            existing.remarks = item.remarks
        else:
            new_result = models.TestResult(
                score=item.score,
                remarks=item.remarks,
                test_id=test_id,
                student_id=item.student_id,
                school_id=test.school_id
            )
            db.add(new_result)
        saved_count += 1

    db.commit()
    return {
        "message": f"Bulk entry complete. {saved_count} results saved.",
        "saved_count": saved_count,
        "errors": errors
    }


@router.get("/tests/{test_id}/results", response_model=List[schemas.TestResult], summary="Get all results for a test")
def get_test_results(
    test_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher"]))
):
    test = db.query(models.CourseTest).filter(models.CourseTest.id == test_id).first()
    if not test:
        raise HTTPException(status_code=404, detail="Course test not found")
    if test.school_id != current_user.school_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    return db.query(models.TestResult).filter(
        models.TestResult.test_id == test_id
    ).order_by(models.TestResult.score.desc()).all()


@router.get("/students/{student_id}/results", response_model=List[schemas.TestResult], summary="Get all test results for a student")
def get_student_test_results(
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

    return db.query(models.TestResult).filter(
        models.TestResult.student_id == student_id
    ).order_by(models.TestResult.recorded_at.desc()).all()


# =============================================================================
# StudentDocument Endpoints
# =============================================================================

@router.post("/students/{student_id}/documents", response_model=schemas.StudentDocument, summary="Attach a document to a student")
def upload_student_document(
    student_id: int,
    doc: schemas.StudentDocumentCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    student = db.query(models.Student).filter(models.Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    if student.school_id != current_user.school_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    new_doc = models.StudentDocument(
        title=doc.title,
        document_type=doc.document_type,
        file_url=doc.file_url,
        notes=doc.notes,
        student_id=student_id,
        uploaded_by=current_user.id
    )
    db.add(new_doc)
    db.commit()
    db.refresh(new_doc)
    return new_doc


@router.get("/students/{student_id}/documents", response_model=List[schemas.StudentDocument], summary="List documents for a student")
def get_student_documents(
    student_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher"]))
):
    student = db.query(models.Student).filter(models.Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    if student.school_id != current_user.school_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    return db.query(models.StudentDocument).filter(
        models.StudentDocument.student_id == student_id
    ).order_by(models.StudentDocument.uploaded_at.desc()).all()
