from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

# --- User Schemas ---
class UserBase(BaseModel):
    email: str

class UserCreate(UserBase):
    password: str
    full_name: str
    role: str = "parent"

class UserLogin(UserBase):
    password: str

class User(UserBase):
    id: int
    full_name: str
    role: str
    is_active: bool

    class Config:
        from_attributes = True

# --- Student Schemas ---
class StudentBase(BaseModel):
    enrollment_number: str
    full_name: str
    grade: str

class StudentCreate(StudentBase):
    parent_id: int

class Student(StudentBase):
    id: int
    parent_id: int

    class Config:
        from_attributes = True

# --- Discount Schemas ---
class DiscountBase(BaseModel):
    name: str
    percentage: float = 0.0
    flat_amount: float = 0.0
    description: Optional[str] = None

class DiscountCreate(DiscountBase):
    pass

class Discount(DiscountBase):
    id: int

    class Config:
        from_attributes = True

# --- Fee Schemas ---
class FeeBase(BaseModel):
    title: str
    amount: float
    due_date: datetime
    student_id: int
    discount_id: Optional[int] = None

class FeeCreate(FeeBase):
    pass

class FeeBulkCreate(BaseModel):
    title: str
    amount: float
    due_date: datetime
    grade: str
    discount_id: Optional[int] = None

class Fee(FeeBase):
    id: int
    status: str
    # computed fields typically handled in response model logic, keeping simple for now

    class Config:
        from_attributes = True

# --- Payment Schemas ---
class PaymentBase(BaseModel):
    fee_id: int
    amount_paid: float
    payment_method: str = "card"

class PaymentCreate(PaymentBase):
    pass

class Payment(PaymentBase):
    id: int
    payment_date: datetime
    transaction_id: str

    class Config:
        from_attributes = True

# --- School Schemas ---
class SchoolBase(BaseModel):
    name: str
    address: Optional[str] = None
    contact_email: Optional[str] = None
    logo_url: Optional[str] = None

class SchoolCreate(SchoolBase):
    pass

class SchoolUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    contact_email: Optional[str] = None
    logo_url: Optional[str] = None

class School(SchoolBase):
    id: int

    class Config:
        from_attributes = True

# --- CSV Import Schema ---
class StudentBulkImport(BaseModel):
    enrollment_number: str
    full_name: str
    grade: str
    parent_email: str

# --- Notification Schemas ---
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

# --- Report Schemas ---
class DashboardStats(BaseModel):
    total_students: int
    total_revenue: float
    outstanding_fees: float
    total_fees_created: float
