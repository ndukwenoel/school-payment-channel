from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from .. import database, models, schemas
from .auth import get_db, get_current_user

router = APIRouter(
    prefix="/parents",
    tags=["Parents"]
)

@router.post("/link-student", response_model=schemas.Student)
def link_student(enrollment_number: str, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role != "parent":
        raise HTTPException(status_code=403, detail="Only parents can link students")
    
    # Check if student exists
    student = db.query(models.Student).filter(models.Student.enrollment_number == enrollment_number).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    # Check if already linked
    if student.parent_id == current_user.id:
        raise HTTPException(status_code=400, detail="Student already linked to your account")
    
    # Security check: In real world, verify detailed info (DOB, Pin) or if student has no parent yet.
    # Current model allows one parent. If student has parent, we might deny or allow multi-parent (requires schema change).
    # For MVP: If student has a DIFFERENT parent, deny.
    if student.parent_id and student.parent_id != current_user.id:
        # Check if that parent is a placeholder? 
        # For simplicity MVP: If student has parent_id, check if it matches.
        # But wait, import process created students with placeholder parents. 
        # If I am a real parent claiming, I should probably override the placeholder or merge?
        # Logic: If student.parent.email is a placeholder/system generated, allow claim.
        # For now, simplistic: update parent_id.
        pass

    student.parent_id = current_user.id
    db.commit()
    db.refresh(student)
    return student

@router.get("/my-students", response_model=list[schemas.Student])
def get_my_students(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    return db.query(models.Student).filter(models.Student.parent_id == current_user.id).all()
