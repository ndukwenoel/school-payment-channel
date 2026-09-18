from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class SchoolBase(BaseModel):
    name: str
    address: Optional[str] = None
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None
    logo_url: Optional[str] = None
    allowed_installment_options: str = "2,3,4"
    enable_late_fees: bool = False
    late_fee_percentage: float = 0.0
    late_fee_grace_period_days: int = 0
    status: str = "active"
    subscription_plan: Optional[str] = None
    subscription_due_date: Optional[datetime] = None
    modules_enabled: Optional[str] = None

class SchoolCreate(SchoolBase):
    pass

class SchoolOnboardRequest(BaseModel):
    school: SchoolCreate
    admin_email: str
    admin_password: str
    admin_name: str

class SchoolUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None
    logo_url: Optional[str] = None
    enable_late_fees: Optional[bool] = None
    late_fee_percentage: Optional[float] = None
    late_fee_grace_period_days: Optional[int] = None
    status: Optional[str] = None
    subscription_plan: Optional[str] = None
    subscription_due_date: Optional[datetime] = None
    modules_enabled: Optional[str] = None

class School(SchoolBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class DashboardStats(BaseModel):
    total_students: int
    total_revenue: float
    outstanding_invoices: float
    total_invoices_created: float



class ClassRoomBase(BaseModel):
    name: str
    section: Optional[str] = None
    school_id: int

class ClassRoomCreate(ClassRoomBase):
    pass

class ClassRoom(ClassRoomBase):
    id: int
    class Config:
        from_attributes = True

class SubjectBase(BaseModel):
    name: str
    code: str
    school_id: int

class SubjectCreate(SubjectBase):
    pass

class Subject(SubjectBase):
    id: int
    class Config:
        from_attributes = True

class AttendanceBase(BaseModel):
    date: datetime
    status: str
    student_id: int
    school_id: int

class AttendanceCreate(AttendanceBase):
    pass

class Attendance(AttendanceBase):
    id: int
    class Config:
        from_attributes = True

class GradeRecordBase(BaseModel):
    score: float
    term: str
    academic_year: str
    student_id: int
    subject_id: int
    school_id: int

class GradeRecordCreate(GradeRecordBase):
    pass

class GradeRecord(GradeRecordBase):
    id: int
    class Config:
        from_attributes = True

class StaffProfileBase(BaseModel):
    employee_id: str
    designation: str
    base_salary: float = 0.0
    user_id: int
    school_id: int

class StaffProfileCreate(StaffProfileBase):
    pass

class StaffProfile(StaffProfileBase):
    id: int
    class Config:
        from_attributes = True

class StaffWithUser(StaffProfileBase):
    """Staff profile enriched with linked user info."""
    id: int
    full_name: Optional[str] = None   # from User.full_name
    email: Optional[str] = None        # from User.email

    class Config:
        from_attributes = True

class StaffWithUser(StaffProfileBase):
    """Staff profile enriched with linked user info."""
    id: int
    full_name: Optional[str] = None   # from User.full_name
    email: Optional[str] = None        # from User.email

    class Config:
        from_attributes = True

class PayrollBase(BaseModel):
    month: str
    year: int
    base_salary: float
    bonuses: float = 0.0
    deductions: float = 0.0
    net_pay: float
    staff_id: int
    school_id: int

class PayrollCreate(PayrollBase):
    pass

class Payroll(PayrollBase):
    id: int
    class Config:
        from_attributes = True

class InventoryItemBase(BaseModel):
    name: str
    category: str
    quantity: int = 0
    unit_price: Optional[float] = None
    is_for_sale: bool = False
    school_id: Optional[int] = None

class InventoryItemCreate(InventoryItemBase):
    pass

class InventoryItem(InventoryItemBase):
    id: int
    class Config:
        from_attributes = True

