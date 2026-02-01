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
    fees = relationship("Fee", back_populates="student")
    attendance_records = relationship("Attendance", back_populates="student")
    grades = relationship("GradeRecord", back_populates="student")

class Fee(Base):
    __tablename__ = "fees"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String) # e.g. "Term 1 Tuition", "Bus Fee"
    amount = Column(Float)
    due_date = Column(DateTime)
    status = Column(String, default="pending") # pending, paid, partial, overdue
    student_id = Column(Integer, ForeignKey("students.id"))
    discount_id = Column(Integer, ForeignKey("discounts.id"), nullable=True)

    student = relationship("Student", back_populates="fees")
    discount = relationship("Discount", back_populates="fees")
    payments = relationship("Payment", back_populates="fee")

class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    fee_id = Column(Integer, ForeignKey("fees.id"))
    amount_paid = Column(Float)
    transaction_id = Column(String)
    payment_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    payment_method = Column(String) # card, bank_transfer

    fee = relationship("Fee", back_populates="payments")

class Discount(Base):
    __tablename__ = "discounts"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g. "Sibling Discount", "Staff Child"
    percentage = Column(Float, default=0.0)
    flat_amount = Column(Float, default=0.0)
    description = Column(String)

    fees = relationship("Fee", back_populates="discount")

class NotificationLog(Base):
    __tablename__ = "notification_logs"

    id = Column(Integer, primary_key=True, index=True)
    recipient_email = Column(String)
    subject = Column(String)
    message = Column(String)
    sent_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    status = Column(String, default="sent") # sent, failed

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

