from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ... import database, models, schemas
from .auth import get_db, CheckRole

router = APIRouter(prefix="/users", tags=["User Management"])

@router.get("/")
def list_all_users(skip: int = 0, limit: int = 5000, role: str = None, school_id: int = None, db: Session = Depends(get_db), current_user: models.User = Depends(CheckRole(["super_admin"]))):
    query = db.query(models.User)
    if role:
        query = query.filter(models.User.role == role)
    if school_id:
        query = query.filter(models.User.school_id == school_id)
    users = query.offset(skip).limit(limit).all()
    return [{"id": u.id, "email": u.email, "full_name": u.full_name, "role": u.role, "is_active": u.is_active, "school_id": u.school_id, "school_name": u.school.name if u.school else None} for u in users]

@router.patch("/{user_id}/role")
def update_user_role(user_id: int, role: str, db: Session = Depends(get_db), current_user: models.User = Depends(CheckRole(["super_admin"]))):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.role = role
    db.commit()
    return {"status": "ok", "user_id": user_id, "new_role": role}
