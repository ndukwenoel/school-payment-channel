from pydantic import BaseModel, Field
from typing import Any, Dict, Optional, Union
from datetime import datetime, timezone
import uuid

class StudentEnrolledPayload(BaseModel):
    student_id: int
    enrollment_number: str
    grade: str

class PaymentReceivedPayload(BaseModel):
    provider: str
    amount: float
    transaction_id: str
    status: str
    payment_id: Optional[int] = None
    invoice_id: Optional[int] = None
    user_email: Optional[str] = None
    raw: Optional[Dict[str, Any]] = None

class InvoiceGeneratedPayload(BaseModel):
    invoice_id: int
    student_id: int
    amount: float

class VirtualAccountFundedPayload(BaseModel):
    student_id: int
    account_number: str
    amount: float
    transaction_ref: str

class BaseEvent(BaseModel):
    event_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    event_type: str
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    school_id: Optional[int] = None
    payload: Union[
        StudentEnrolledPayload, 
        PaymentReceivedPayload, 
        InvoiceGeneratedPayload, 
        VirtualAccountFundedPayload,
        Dict[str, Any]
    ]
    
    class Config:
        from_attributes = True
