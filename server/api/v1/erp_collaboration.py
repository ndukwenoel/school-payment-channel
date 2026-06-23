from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from ... import database, models, schemas
from .auth import get_db, CheckRole

router = APIRouter(
    prefix="/erp/collaboration",
    tags=["ERP Collaboration"]
)

# --- Broadcasts ---
@router.post("/broadcasts", response_model=schemas.Broadcast)
def create_broadcast(
    broadcast: schemas.BroadcastCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")

    if broadcast.school_id and broadcast.school_id != current_user.school_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    if not broadcast.school_id:
        broadcast.school_id = current_user.school_id

    # Exclude send_whatsapp from model dump since it's not in the DB model
    b_dict = broadcast.model_dump(exclude={"send_whatsapp"})
    new_broadcast = models.Broadcast(**b_dict)
    db.add(new_broadcast)
    
    # Logic to send notifications to all parents would go here
    if broadcast.send_whatsapp:
        # Mocking WhatsApp broadcast integration
        print(f"--- MOCK WHATSAPP BROADCAST ---")
        print(f"School ID: {broadcast.school_id}")
        print(f"Title: {broadcast.title}")
        print(f"Message: {broadcast.message}")
        print(f"-------------------------------")
    
    db.commit()
    db.refresh(new_broadcast)
    return new_broadcast

@router.get("/broadcasts", response_model=List[schemas.Broadcast])
def get_broadcasts(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher", "parent"]))
):
    if current_user.role == "parent":
        # Find parent's school(s) via students
        student = db.query(models.Student).filter(models.Student.parent_id == current_user.id).first()
        if not student or not student.school_id:
            return []
        return db.query(models.Broadcast).filter(models.Broadcast.school_id == student.school_id).all()
        
    return db.query(models.Broadcast).filter(models.Broadcast.school_id == current_user.school_id).all()

# --- Academic Resources (Teacher Uploads) ---
@router.post("/resources", response_model=schemas.AcademicResource)
def upload_resource(
    resource: schemas.AcademicResourceCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin", "teacher"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to a school")

    if resource.school_id and resource.school_id != current_user.school_id:
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    if not resource.school_id:
        resource.school_id = current_user.school_id

    # Auto-approve if admin uploads, else pending
    status = "approved" if current_user.role in ["admin", "school_admin"] else "pending"
    
    # Enforce internal visibility for exams/tests regardless of input
    visibility = resource.visibility
    if resource.type in ["exam", "test"]:
        visibility = "internal"

    new_resource = models.AcademicResource(
        **resource.model_dump(exclude={"visibility"}), # exclude to manually set
        visibility=visibility,
        status=status,
        teacher_id=current_user.id
    )
    db.add(new_resource)
    db.commit()
    db.refresh(new_resource)
    return new_resource

@router.get("/resources/pending", response_model=List[schemas.AcademicResource])
def get_pending_resources(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    return db.query(models.AcademicResource).filter(
        models.AcademicResource.school_id == current_user.school_id,
        models.AcademicResource.status == "pending"
    ).all()

@router.put("/resources/{resource_id}/status", response_model=schemas.AcademicResource)
def update_resource_status(
    resource_id: int,
    status: str, # approved, rejected
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    res = db.query(models.AcademicResource).filter(models.AcademicResource.id == resource_id).first()
    if not res or res.school_id != current_user.school_id:
        raise HTTPException(status_code=404, detail="Resource not found")
        
    res.status = status
    db.commit()
    db.refresh(res)
    return res

@router.get("/resources/public", response_model=List[schemas.AcademicResource])
def get_public_resources(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["parent", "student"]))
):
    # This logic needs to find the correct school for the parent/student
    # Simplifying for parent:
    if current_user.role == "parent":
        student = db.query(models.Student).filter(models.Student.parent_id == current_user.id).first()
        if not student: return []
        school_id = student.school_id
    else:
        # If student login implemented later
        return []

    return db.query(models.AcademicResource).filter(
        models.AcademicResource.school_id == school_id,
        models.AcademicResource.visibility == "public",
        models.AcademicResource.status == "approved"
    ).all()
