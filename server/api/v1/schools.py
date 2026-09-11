from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
from ... import database, models, schemas
from .auth import get_db, get_current_user, CheckRole

router = APIRouter(
    prefix="/schools",
    tags=["Schools"]
)

@router.on_event("startup")
async def create_default_school():
    # Helper to ensure at least one school exists for testing
    db = database.SessionLocal()
    if db.query(models.School).count() == 0:
        db.add(models.School(name="Default School", address="123 Education St", contact_email="admin@school.com"))
        db.commit()
    db.close()

@router.get("/", response_model=list[schemas.School])
def list_all_schools(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["super_admin"]))
):
    return db.query(models.School).all()

@router.post("/onboard", response_model=schemas.School)
def onboard_school(
    req: schemas.SchoolOnboardRequest, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(CheckRole(["super_admin"]))
):
    # Check if school exists
    db_school = db.query(models.School).filter(models.School.name == req.school.name).first()
    if db_school:
        raise HTTPException(status_code=400, detail="School already registered")
        
    # Check if admin email exists
    db_user = db.query(models.User).filter(models.User.email == req.admin_email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Admin email already exists")

    # 1. Create School
    new_school = models.School(**req.school.dict())
    db.add(new_school)
    db.commit()
    db.refresh(new_school)
    
    # 2. Create Admin User
    hashed_password = security.get_password_hash(req.admin_password)
    new_user = models.User(
        email=req.admin_email,
        full_name=req.admin_name,
        hashed_password=hashed_password,
        role="school_admin",
        school_id=new_school.id
    )
    db.add(new_user)
    db.commit()
    
    return new_school

@router.patch("/{school_id}", response_model=schemas.School)
def update_school_admin_level(
    school_id: int,
    update_data: dict,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["super_admin"]))
):
    school = db.query(models.School).filter(models.School.id == school_id).first()
    if not school:
        raise HTTPException(status_code=404, detail="School not found")
        
    if "status" in update_data:
        new_status = update_data.get("status")
        if new_status not in ["active", "suspended"]:
            raise HTTPException(status_code=400, detail="Invalid status")
        school.status = new_status
        
    if "modules_enabled" in update_data:
        school.modules_enabled = update_data.get("modules_enabled")
        
    db.commit()
    db.refresh(school)
    return school

@router.get("/me", response_model=schemas.School)
def read_my_school(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.school_id is None:
        if current_user.role == "super_admin" or not current_user.school_id:
            return schemas.School(
                id=0, 
                name="System Wide (Super Admin)", 
                address="N/A", 
                contact_email="super@system.com",
                contact_phone="N/A",
                created_at=datetime.utcnow()
            )
        raise HTTPException(status_code=404, detail="User not assigned to any school")
    
    school = db.query(models.School).filter(models.School.id == current_user.school_id).first()
    if school is None:
        raise HTTPException(status_code=404, detail="School not found")
    return school

@router.put("/me", response_model=schemas.School)
def update_school(school_update: schemas.SchoolUpdate, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.role not in ["admin", "school_admin"]:
        raise HTTPException(status_code=403, detail="Not authorized to update school profile")
    
    if current_user.school_id is None:
         raise HTTPException(status_code=404, detail="User not assigned to any school")

    db_school = db.query(models.School).filter(models.School.id == current_user.school_id).first()
    if not db_school:
         raise HTTPException(status_code=404, detail="School not found")

    if school_update.name: db_school.name = school_update.name
    if school_update.address: db_school.address = school_update.address
    if school_update.contact_email: db_school.contact_email = school_update.contact_email
    if school_update.contact_phone is not None: db_school.contact_phone = school_update.contact_phone
    if school_update.logo_url: db_school.logo_url = school_update.logo_url
    if school_update.enable_late_fees is not None: db_school.enable_late_fees = school_update.enable_late_fees
    if school_update.late_fee_percentage is not None: db_school.late_fee_percentage = school_update.late_fee_percentage
    if school_update.late_fee_grace_period_days is not None: db_school.late_fee_grace_period_days = school_update.late_fee_grace_period_days
    if school_update.modules_enabled is not None: db_school.modules_enabled = school_update.modules_enabled
    
    db.commit()
    db.refresh(db_school)
    return db_school
