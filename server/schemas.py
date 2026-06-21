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

class StudentBulkPromote(BaseModel):
    current_grade: str
    new_grade: str

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

# --- Invoice Line Item Schemas ---
class InvoiceLineItemBase(BaseModel):
    title: str
    amount: float

class InvoiceLineItemCreate(InvoiceLineItemBase):
    pass

class InvoiceLineItem(InvoiceLineItemBase):
    id: int
    invoice_id: int

    class Config:
        from_attributes = True

# --- Invoice Schemas ---
class InvoiceBase(BaseModel):
    title: str
    due_date: datetime
    student_id: int
    discount_id: Optional[int] = None

class InvoiceCreate(InvoiceBase):
    line_items: List[InvoiceLineItemCreate]

class InvoiceBulkCreate(BaseModel):
    title: str
    due_date: datetime
    grade: str
    discount_id: Optional[int] = None
    line_items: List[InvoiceLineItemCreate]

class Invoice(InvoiceBase):
    id: int
    status: str
    line_items: List[InvoiceLineItem] = []

    class Config:
        from_attributes = True

# --- Fee Template Schemas ---
class FeeTemplateLineItemBase(BaseModel):
    title: str
    amount: float

class FeeTemplateLineItemCreate(FeeTemplateLineItemBase):
    pass

class FeeTemplateLineItem(FeeTemplateLineItemBase):
    id: int
    template_id: int

    class Config:
        from_attributes = True

class FeeTemplateBase(BaseModel):
    name: str
    description: Optional[str] = None

class FeeTemplateCreate(FeeTemplateBase):
    line_items: List[FeeTemplateLineItemCreate]

class FeeTemplate(FeeTemplateBase):
    id: int
    school_id: int
    line_items: List[FeeTemplateLineItem] = []

    class Config:
        from_attributes = True

# --- Installment Schemas ---
class InstallmentBase(BaseModel):
    amount_due: float
    due_date: datetime

class InstallmentCreate(InstallmentBase):
    pass

class Installment(InstallmentBase):
    id: int
    plan_id: int
    status: str

    class Config:
        from_attributes = True

class InstallmentPlanBase(BaseModel):
    invoice_id: int

class InstallmentPlanCreate(InstallmentPlanBase):
    installments: List[InstallmentCreate]

class InstallmentPlan(InstallmentPlanBase):
    id: int
    school_id: int
    installments: List[Installment] = []

    class Config:
        from_attributes = True

# --- Payment Attempt Schemas ---
class PaymentAttemptBase(BaseModel):
    invoice_id: int
    amount: float
    provider: str = "paystack"

class PaymentAttemptCreate(PaymentAttemptBase):
    pass

class PaymentAttempt(PaymentAttemptBase):
    id: int
    status: str
    transaction_id: Optional[str] = None
    payment_date: datetime

    class Config:
        from_attributes = True

# --- Virtual Account Schemas ---
class VirtualAccountBase(BaseModel):
    account_number: str
    account_name: str
    bank_name: str
    student_id: int
    school_id: int

class VirtualAccountCreate(VirtualAccountBase):
    pass

class VirtualAccount(VirtualAccountBase):
    id: int
    status: str
    created_at: datetime

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
    outstanding_invoices: float
    total_invoices_created: float

# --- ERP Schemas ---

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
    school_id: int

class InventoryItemCreate(InventoryItemBase):
    pass

class InventoryItem(InventoryItemBase):
    id: int
    class Config:
        from_attributes = True

# --- Collaboration Schemas ---

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

# --- Collaboration Schemas ---

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

# --- CourseTest Schemas ---

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

# --- TestResult Schemas ---

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

# --- StudentDocument Schemas ---

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

# --- Ledger Schemas ---

class PostingRuleBase(BaseModel):
    event_type: str
    provider: Optional[str] = None
    debit_account_name: str
    credit_account_name: str
    school_id: Optional[int] = None

class PostingRuleCreate(PostingRuleBase):
    pass

class PostingRule(PostingRuleBase):
    id: int
    class Config:
        from_attributes = True

# --- Financial Intelligence Schemas ---

class AgingBucket(BaseModel):
    bucket: str # "0-30 days", "31-60 days", "61-90 days", "90+ days"
    total_amount: float
    invoice_ids: List[int]

class AgingReportResponse(BaseModel):
    total_overdue: float
    buckets: List[AgingBucket]

class RevenueBreakdown(BaseModel):
    category: str
    amount: float

class RevenueReportResponse(BaseModel):
    total_revenue: float
    breakdowns: List[RevenueBreakdown] = []
    
class ExpectedSettlementResponse(BaseModel):
    total_expected: float
    providers: dict # e.g. {"paystack": 5000, "flutterwave": 1000}

