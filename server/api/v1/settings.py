from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from ... import database, models, schemas
from .auth import get_db, CheckRole

router = APIRouter(
    prefix="/settings",
    tags=["System Settings"]
)

@router.get("/", response_model=schemas.SystemSettings)
def get_system_settings(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["super_admin"]))
):
    settings = db.query(models.SystemSettings).first()
    if not settings:
        settings = models.SystemSettings()
        db.add(settings)
        db.commit()
        db.refresh(settings)
    return settings

@router.patch("/", response_model=schemas.SystemSettings)
def update_system_settings(
    update_data: schemas.SystemSettingsUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["super_admin"]))
):
    settings = db.query(models.SystemSettings).first()
    if not settings:
        settings = models.SystemSettings()
        db.add(settings)
    
    update_dict = update_data.model_dump(exclude_unset=True)
    for k, v in update_dict.items():
        setattr(settings, k, v)
        
    db.commit()
    db.refresh(settings)
    
    # Audit log
    audit = models.AuditLog(
        user_id=current_user.id,
        action="UPDATE",
        table_name="system_settings",
        record_id=str(settings.id),
        new_values=f"Updated settings keys: {list(update_dict.keys())}"
    )
    db.add(audit)
    db.commit()
    
    return settings
