from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class StudentBase(BaseModel):
    enrollment_number: str
    full_name: str
    grade: str
    date_of_birth: Optional[datetime] = None
    gender: Optional[str] = None
    profile_picture_url: Optional[str] = None
    home_address: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    blood_group: Optional[str] = None
    genotype: Optional[str] = None
    allergies: Optional[str] = None
    medical_conditions: Optional[str] = None
    admission_date: Optional[datetime] = None
    status: str = "active"

class StudentCreate(StudentBase):
    parent_id: int

class StudentCreateAdmin(StudentBase):
    """Admin-friendly create — auto-creates a parent user from email."""
    parent_email: str
    classroom_id: Optional[int] = None

class StudentUpdate(BaseModel):
    """PATCH payload — all fields optional."""
    full_name: Optional[str] = None
    grade: Optional[str] = None
    classroom_id: Optional[int] = None
    date_of_birth: Optional[datetime] = None
    gender: Optional[str] = None
    profile_picture_url: Optional[str] = None
    home_address: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    blood_group: Optional[str] = None
    genotype: Optional[str] = None
    allergies: Optional[str] = None
    medical_conditions: Optional[str] = None
    admission_date: Optional[datetime] = None
    status: Optional[str] = None

from .finance import VirtualAccount

class Student(StudentBase):
    id: int
    parent_id: int
    school_id: Optional[int] = None
    classroom_id: Optional[int] = None
    classroom_name: Optional[str] = None  # computed from relationship
    virtual_accounts: List[VirtualAccount] = []

    class Config:
        from_attributes = True

class StudentBulkPromote(BaseModel):
    current_grade: str
    new_grade: str



class StudentDocumentBase(BaseModel):
    title: str
    document_type: str  # medical, academic, behavioral, identification, other
    file_url: str
    notes: Optional[str] = None
    student_id: int

class StudentDocumentCreate(StudentDocumentBase):
    pass

class StudentDocument(StudentDocumentBase):
    id: int
    uploaded_at: datetime
    uploaded_by: Optional[int] = None

    class Config:
        from_attributes = True

