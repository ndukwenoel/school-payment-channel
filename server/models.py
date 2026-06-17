from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    full_name = Column(String)
    role = Column(String, default="parent") # parent, admin, school_admin
    is_active = Column(Boolean, default=True)
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)

    students = relationship("Student", back_populates="parent")
    school = relationship("School", back_populates="users")

class School(Base):
    __tablename__ = "schools"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    address = Column(String)
    contact_email = Column(String)
    logo_url = Column(String, nullable=True)
    
    users = relationship("User", back_populates="school")
    students = relationship("Student", back_populates="school")
    classrooms = relationship("ClassRoom", back_populates="school")
    subjects = relationship("Subject", back_populates="school")
    attendance_records = relationship("Attendance", back_populates="school")
    grades = relationship("GradeRecord", back_populates="school")
    staff = relationship("StaffProfile", back_populates="school")
    payrolls = relationship("Payroll", back_populates="school")
    inventory = relationship("InventoryItem", back_populates="school")
    broadcasts = relationship("Broadcast", back_populates="school")
    resources = relationship("AcademicResource", back_populates="school")

class Student(Base):
    __tablename__ = "students"

    id = Column(Integer, primary_key=True, index=True)
    enrollment_number = Column(String, unique=True, index=True)
    full_name = Column(String)
    grade = Column(String)
    parent_id = Column(Integer, ForeignKey("users.id"))
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)

    parent = relationship("User", back_populates="students")
    school = relationship("School", back_populates="students")
    classroom_id = Column(Integer, ForeignKey("classrooms.id"), nullable=True)
    
    classroom = relationship("ClassRoom", back_populates="students")
    invoices = relationship("Invoice", back_populates="student")
    attendance_records = relationship("Attendance", back_populates="student")
    grades = relationship("GradeRecord", back_populates="student")
    virtual_accounts = relationship("VirtualAccount", back_populates="student")

class VirtualAccount(Base):
    __tablename__ = "virtual_accounts"

    id = Column(Integer, primary_key=True, index=True)
    account_number = Column(String, unique=True, index=True)
    account_name = Column(String)
    bank_name = Column(String)
    student_id = Column(Integer, ForeignKey("students.id"))
    school_id = Column(Integer, ForeignKey("schools.id"))
    status = Column(String, default="active") # active, inactive
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    student = relationship("Student", back_populates="virtual_accounts")
    school = relationship("School")

class Invoice(Base):
    __tablename__ = "invoices"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String) # e.g. "Term 1 Invoice"
    due_date = Column(DateTime)
    status = Column(String, default="pending") # pending, paid, partial, overdue
    student_id = Column(Integer, ForeignKey("students.id"))
    discount_id = Column(Integer, ForeignKey("discounts.id"), nullable=True)
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)

    student = relationship("Student", back_populates="invoices")
    discount = relationship("Discount", back_populates="invoices")
    line_items = relationship("InvoiceLineItem", back_populates="invoice")
    payment_attempts = relationship("PaymentAttempt", back_populates="invoice")

class InvoiceLineItem(Base):
    __tablename__ = "invoice_line_items"

    id = Column(Integer, primary_key=True, index=True)
    invoice_id = Column(Integer, ForeignKey("invoices.id"))
    title = Column(String)
    amount = Column(Float)
    
    invoice = relationship("Invoice", back_populates="line_items")

class PaymentAttempt(Base):
    __tablename__ = "payment_attempts"

    id = Column(Integer, primary_key=True, index=True)
    invoice_id = Column(Integer, ForeignKey("invoices.id"))
    amount = Column(Float)
    provider = Column(String) # paystack, flutterwave, mock
    status = Column(String, default="pending") # pending, success, failed
    transaction_id = Column(String, nullable=True)
    payment_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)

    invoice = relationship("Invoice", back_populates="payment_attempts")

class Discount(Base):
    __tablename__ = "discounts"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g. "Sibling Discount", "Staff Child"
    percentage = Column(Float, default=0.0)
    flat_amount = Column(Float, default=0.0)
    description = Column(String)
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)

    invoices = relationship("Invoice", back_populates="discount")

class NotificationLog(Base):
    __tablename__ = "notification_logs"

    id = Column(Integer, primary_key=True, index=True)
    recipient_email = Column(String)
    subject = Column(String)
    message = Column(String)
    sent_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    status = Column(String, default="sent") # sent, failed
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)

class ClassRoom(Base):
    __tablename__ = "classrooms"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g. "Grade 10 - Blue"
    section = Column(String, nullable=True) # e.g. "A", "B"
    school_id = Column(Integer, ForeignKey("schools.id"))

    school = relationship("School", back_populates="classrooms")
    students = relationship("Student", back_populates="classroom")

# Update Student to link to ClassRoom
# Note: Keeping the original Student definition for now but adding a foreign key for ClassRoom later if needed.
# For simplicity in this step, I'll update the Student model in the next chunk if necessary or just add ClassRoom relationship.

class Subject(Base):
    __tablename__ = "subjects"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g. "Mathematics"
    code = Column(String) # e.g. "MATH101"
    school_id = Column(Integer, ForeignKey("schools.id"))

    school = relationship("School", back_populates="subjects")

class Attendance(Base):
    __tablename__ = "attendance"

    id = Column(Integer, primary_key=True, index=True)
    date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    status = Column(String) # present, absent, late
    student_id = Column(Integer, ForeignKey("students.id"))
    school_id = Column(Integer, ForeignKey("schools.id"))

    student = relationship("Student", back_populates="attendance_records")
    school = relationship("School", back_populates="attendance_records")

class GradeRecord(Base):
    __tablename__ = "grade_records"

    id = Column(Integer, primary_key=True, index=True)
    score = Column(Float)
    term = Column(String) # e.g. "Term 1"
    academic_year = Column(String) # e.g. "2025/2026"
    student_id = Column(Integer, ForeignKey("students.id"))
    subject_id = Column(Integer, ForeignKey("subjects.id"))
    school_id = Column(Integer, ForeignKey("schools.id"))

    student = relationship("Student", back_populates="grades")
    school = relationship("School", back_populates="grades")

class StaffProfile(Base):
    __tablename__ = "staff_profiles"

    id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(String, unique=True, index=True)
    designation = Column(String) # e.g. "Teacher", "Accountant"
    base_salary = Column(Float, default=0.0)
    user_id = Column(Integer, ForeignKey("users.id"))
    school_id = Column(Integer, ForeignKey("schools.id"))

    user = relationship("User")
    school = relationship("School", back_populates="staff")
    payrolls = relationship("Payroll", back_populates="staff")

class Payroll(Base):
    __tablename__ = "payrolls"

    id = Column(Integer, primary_key=True, index=True)
    month = Column(String) # e.g. "January"
    year = Column(Integer)
    base_salary = Column(Float)
    bonuses = Column(Float, default=0.0)
    deductions = Column(Float, default=0.0)
    net_pay = Column(Float)
    staff_id = Column(Integer, ForeignKey("staff_profiles.id"))
    school_id = Column(Integer, ForeignKey("schools.id"))

    staff = relationship("StaffProfile", back_populates="payrolls")
    school = relationship("School", back_populates="payrolls")

class InventoryItem(Base):
    __tablename__ = "inventory_items"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g. "Whiteboard Marker"
    category = Column(String) # e.g. "Stationery", "Lab"
    quantity = Column(Integer, default=0)
    unit_price = Column(Float, nullable=True)
    school_id = Column(Integer, ForeignKey("schools.id"))

    school = relationship("School", back_populates="inventory")

class Broadcast(Base):
    __tablename__ = "broadcasts"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    message = Column(String)
    type = Column(String) # newsletter, alert, event
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    school_id = Column(Integer, ForeignKey("schools.id"))

    school = relationship("School", back_populates="broadcasts")

class AcademicResource(Base):
    __tablename__ = "academic_resources"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    description = Column(String, nullable=True)
    file_url = Column(String)
    type = Column(String) # note, exam, test
    status = Column(String, default="pending") # pending, approved, rejected
    visibility = Column(String, default="internal") # internal, public
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    school_id = Column(Integer, ForeignKey("schools.id"))
    teacher_id = Column(Integer, ForeignKey("users.id")) # uploader
    classroom_id = Column(Integer, ForeignKey("classrooms.id"), nullable=True) # specific class targeting

    school = relationship("School", back_populates="resources")
    teacher = relationship("User")
    classroom = relationship("ClassRoom")

# --- RBAC Models ---
class Role(Base):
    __tablename__ = "roles"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g., "bursar", "principal"
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)

    permissions = relationship("RolePermission", back_populates="role")

class Permission(Base):
    __tablename__ = "permissions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True) # e.g., "can_create_fee"

class RolePermission(Base):
    __tablename__ = "role_permissions"

    id = Column(Integer, primary_key=True, index=True)
    role_id = Column(Integer, ForeignKey("roles.id"))
    permission_id = Column(Integer, ForeignKey("permissions.id"))

    role = relationship("Role", back_populates="permissions")
    permission = relationship("Permission")

# --- Audit Log ---
class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    action = Column(String) # e.g., "UPDATE", "INSERT"
    table_name = Column(String)
    record_id = Column(String)
    old_values = Column(String) # String for dev DB portability, JSON in prod
    new_values = Column(String)
    ip_address = Column(String, nullable=True)
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc))

# --- Ledger Models ---
class LedgerAccount(Base):
    __tablename__ = "ledger_accounts"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g., "Parent Wallet", "School Revenue"
    type = Column(String) # asset, liability, equity, revenue, expense
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)

class LedgerTransaction(Base):
    __tablename__ = "ledger_transactions"

    id = Column(Integer, primary_key=True, index=True)
    description = Column(String)
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    entries = relationship("LedgerEntry", back_populates="transaction")

class LedgerEntry(Base):
    __tablename__ = "ledger_entries"

    id = Column(Integer, primary_key=True, index=True)
    transaction_id = Column(Integer, ForeignKey("ledger_transactions.id"))
    account_id = Column(Integer, ForeignKey("ledger_accounts.id"))
    amount = Column(Float)
    type = Column(String) # "debit" or "credit"
    
    transaction = relationship("LedgerTransaction", back_populates="entries")
    account = relationship("LedgerAccount")

class PostingRule(Base):
    __tablename__ = "posting_rules"

    id = Column(Integer, primary_key=True, index=True)
    event_type = Column(String) # e.g. "payment.received", "payment.exception"
    provider = Column(String, nullable=True) # e.g. "paystack", "mock", "virtual_account"
    debit_account_name = Column(String)
    credit_account_name = Column(String)
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)
