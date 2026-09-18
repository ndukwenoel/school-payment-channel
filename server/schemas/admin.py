from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class StudentBulkImport(BaseModel):
    enrollment_number: str
    full_name: str
    grade: str
    parent_email: str


class NotificationBase(BaseModel):
    recipient_email: str
    subject: str
    message: str

class NotificationCreate(NotificationBase):
    pass

class NotificationLog(NotificationBase):
    id: int
    sent_at: datetime
    status: str

    class Config:
        from_attributes = True

