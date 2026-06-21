from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel
from ... import database, models, schemas
from .auth import get_db, CheckRole

router = APIRouter(
    prefix="/erp/hr",
    tags=["ERP HR"]
)

@router.post("/staff", response_model=schemas.StaffWithUser)
def create_staff_profile(
    staff: schemas.StaffProfileCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if staff.school_id != current_user.school_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized for this school")
    
    new_staff = models.StaffProfile(**staff.dict())
    db.add(new_staff)
    db.commit()
    db.refresh(new_staff)
    
    # Map user fields
    s_dict = new_staff.__dict__.copy()
    if new_staff.user:
        s_dict["full_name"] = new_staff.user.full_name
        s_dict["email"] = new_staff.user.email
    return s_dict

@router.get("/staff", response_model=List[schemas.StaffWithUser])
def get_staff_list(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    staff_list = db.query(models.StaffProfile).filter(models.StaffProfile.school_id == current_user.school_id).all()
    result = []
    for s in staff_list:
        s_dict = s.__dict__.copy()
        if s.user:
            s_dict["full_name"] = s.user.full_name
            s_dict["email"] = s.user.email
        result.append(s_dict)
    return result

class StaffCreateAdmin(BaseModel):
    employee_id: str
    designation: str
    base_salary: float = 0.0
    email: str
    full_name: str

@router.post("/staff/admin", response_model=schemas.StaffWithUser)
def create_staff_and_user(
    staff_data: StaffCreateAdmin,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if not current_user.school_id:
        raise HTTPException(status_code=400, detail="User not assigned to school")

    # Check or create User
    user = db.query(models.User).filter(models.User.email == staff_data.email).first()
    if not user:
        from ..security import get_password_hash
        user = models.User(
            email=staff_data.email,
            hashed_password=get_password_hash("password123"),
            full_name=staff_data.full_name,
            role="teacher",
            school_id=current_user.school_id
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    existing = db.query(models.StaffProfile).filter(models.StaffProfile.employee_id == staff_data.employee_id, models.StaffProfile.school_id == current_user.school_id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Employee ID already exists")

    new_staff = models.StaffProfile(
        employee_id=staff_data.employee_id,
        designation=staff_data.designation,
        base_salary=staff_data.base_salary,
        user_id=user.id,
        school_id=current_user.school_id
    )
    db.add(new_staff)
    db.commit()
    db.refresh(new_staff)

    s_dict = new_staff.__dict__.copy()
    s_dict["full_name"] = user.full_name
    s_dict["email"] = user.email
    return s_dict

@router.post("/payroll", response_model=schemas.Payroll)
def generate_payroll(
    payroll: schemas.PayrollCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    if payroll.school_id != current_user.school_id:
        raise HTTPException(status_code=403, detail="Not authorized for this school")

    new_payroll = models.Payroll(**payroll.model_dump())
    db.add(new_payroll)
    db.commit()
    db.refresh(new_payroll)
    return new_payroll

@router.post("/payroll/generate", response_model=dict)
def generate_monthly_payroll(
    month: str,
    year: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    # Check if payroll already exists for this month/year for this school
    existing = db.query(models.Payroll).filter(
        models.Payroll.month == month,
        models.Payroll.year == year,
        models.Payroll.school_id == current_user.school_id
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail=f"Payroll for {month} {year} already generated")

    staff_list = db.query(models.StaffProfile).filter(
        models.StaffProfile.school_id == current_user.school_id
    ).all()
    
    if not staff_list:
        return {"message": "No staff found to generate payroll", "count": 0}

    count = 0
    for staff in staff_list:
        # Simple logic: Net Pay = Base Salary + Bonuses - Deductions
        # For automation, we can default bonuses/deductions to 0 or fetch from a helper table if it existed.
        # Here we assume base salary from a contract (not yet in model, so using a default or adding to schema)
        # Wait, the Payroll model has base_salary, but StaffProfile doesn't store it.
        # I should update StaffProfile to include `base_salary` to make this work automatically.
        # But for now, to respect current schema, I will create a Payroll entry with 0 or a placeholder.
        # Actually, let's update schema immediately after this block to be realistic.
        
        # Determining a mock base salary based on designation for now if not present
        # base = 5000.0 if "Teacher" in staff.designation else 7000.0
        # NOW USING REAL DB VALUE
        base = staff.base_salary
        
        payroll = models.Payroll(
            month=month,
            year=year,
            base_salary=base, # In real app, this comes from StaffProfile.base_salary
            bonuses=0.0,
            deductions=0.0,
            net_pay=base,
            staff_id=staff.id,
            school_id=current_user.school_id
        )
        db.add(payroll)
        count += 1

    db.commit()
    return {"message": f"Payroll generated successfully for {count} staff members", "count": count}

@router.get("/payroll/staff/{staff_id}", response_model=List[schemas.Payroll])
def get_staff_payroll(
    staff_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["admin", "school_admin"]))
):
    staff = db.query(models.StaffProfile).filter(models.StaffProfile.id == staff_id).first()
    if not staff or staff.school_id != current_user.school_id:
        raise HTTPException(status_code=404, detail="Staff member not found in your school")

    return db.query(models.Payroll).filter(models.Payroll.staff_id == staff_id).all()
