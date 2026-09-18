from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime


class BroadcastBase(BaseModel):
    title: str
    message: str
    type: str = "newsletter"
    school_id: Optional[int] = None
    send_whatsapp: bool = False

class BroadcastCreate(BroadcastBase):
    pass

class Broadcast(BroadcastBase):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True

class AcademicResourceBase(BaseModel):
    title: str
    description: Optional[str] = None
    file_url: str
    type: str # note, exam, test
    visibility: str = "internal" # internal (default), public
    school_id: Optional[int] = None
    classroom_id: Optional[int] = None

class AcademicResourceCreate(AcademicResourceBase):
    pass

class AcademicResource(AcademicResourceBase):
    id: int
    status: str
    created_at: datetime
    teacher_id: int
    class Config:
        from_attributes = True



class BroadcastBase(BaseModel):
    title: str
    message: str
    type: str = "newsletter"
    school_id: int

class BroadcastCreate(BroadcastBase):
    pass

class Broadcast(BroadcastBase):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True

class AcademicResourceBase(BaseModel):
    title: str
    description: Optional[str] = None
    file_url: str
    type: str # note, exam, test
    visibility: str = "internal" # internal (default), public
    school_id: int
    classroom_id: Optional[int] = None

class AcademicResourceCreate(AcademicResourceBase):
    pass

class AcademicResource(AcademicResourceBase):
    id: int
    status: str
    created_at: datetime
    teacher_id: int
    class Config:
        from_attributes = True



class CourseTestBase(BaseModel):
    title: str
    test_type: str  # "test", "exam", "ca", "quiz", "assignment"
    max_score: float = 100.0
    weight_percentage: Optional[float] = None
    term: str
    academic_year: str
    date_administered: Optional[datetime] = None
    subject_id: int
    classroom_id: int
    school_id: int

class CourseTestCreate(CourseTestBase):
    pass

class CourseTest(CourseTestBase):
    id: int
    created_by: int

    class Config:
        from_attributes = True



class TestResultBase(BaseModel):
    score: float
    remarks: Optional[str] = None
    test_id: int
    student_id: int
    school_id: int

class TestResultCreate(TestResultBase):
    pass

class TestResult(TestResultBase):
    id: int
    recorded_at: datetime

    class Config:
        from_attributes = True

class SingleStudentResult(BaseModel):
    student_id: int
    score: float
    remarks: Optional[str] = None

class BulkTestResultCreate(BaseModel):
    """Record scores for multiple students in a single call."""
    results: List[SingleStudentResult]

