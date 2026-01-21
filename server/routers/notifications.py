from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from .. import database, models, schemas
from .auth import get_db, get_current_user

router = APIRouter(
    prefix="/notifications",
    tags=["Notifications"]
)

@router.post("/send", response_model=schemas.NotificationLog)
def send_notification(notification: schemas.NotificationCreate, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    # Mock sending Service (e.g. log to console)
    print(f"--- MOCK EMAIL ---")
    print(f"To: {notification.recipient_email}")
    print(f"Subject: {notification.subject}")
    print(f"Message: {notification.message}")
    print(f"------------------")

    new_log = models.NotificationLog(
        recipient_email=notification.recipient_email,
        subject=notification.subject,
        message=notification.message,
        status="sent"
    )
    db.add(new_log)
    db.commit()
    db.refresh(new_log)
    return new_log

@router.get("/history", response_model=list[schemas.NotificationLog])
def get_notification_history(db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    if current_user.role not in ["admin", "school_admin"]:
         raise HTTPException(status_code=403, detail="Not authorized")
    
    return db.query(models.NotificationLog).order_by(models.NotificationLog.sent_at.desc()).all()
