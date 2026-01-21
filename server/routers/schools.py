from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from .. import database, models, schemas
from .auth import get_db
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from .. import security

router = APIRouter(
    prefix="/schools",
    tags=["Schools"]
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, security.SECRET_KEY, algorithms=[security.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    user = db.query(models.User).filter(models.User.email == email).first()
    if user is None:
        raise credentials_exception
    return user

@router.on_event("startup")
async def create_default_school():
    # Helper to ensure at least one school exists for testing
    db = database.SessionLocal()
    if db.query(models.School).count() == 0:
        db.add(models.School(name="Default School", address="123 Education St", contact_email="admin@school.com"))
        db.commit()
    db.close()

@router.post("/", response_model=schemas.School)
def create_school(school: schemas.SchoolCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # Simple check: only allow if user is super admin (hypothetically) or role check
    # For now allowing any auth user to create for demo
    db_school = db.query(models.School).filter(models.School.name == school.name).first()
    if db_school:
        raise HTTPException(status_code=400, detail="School already registered")
    new_school = models.School(**school.dict())
    db.add(new_school)
    db.commit()
    db.refresh(new_school)
    return new_school

@router.get("/me", response_model=schemas.School)
def read_my_school(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.school_id is None:
        # Fallback for demo: if user has no school, assign to first school
        first_school = db.query(models.School).first()
        if first_school:
             current_user.school_id = first_school.id
             db.commit()
             return first_school
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
    if school_update.logo_url: db_school.logo_url = school_update.logo_url
    
    db.commit()
    db.refresh(db_school)
    return db_school
