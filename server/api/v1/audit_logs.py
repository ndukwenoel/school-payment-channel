from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from ... import database, models, schemas
from .auth import get_db, CheckRole

router = APIRouter(
    prefix="/audit-logs",
    tags=["Audit Logs"]
)

@router.get("/", response_model=List[schemas.AuditLog])
def get_audit_logs(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(CheckRole(["super_admin"]))
):
    return db.query(models.AuditLog).order_by(models.AuditLog.timestamp.desc()).limit(200).all()
