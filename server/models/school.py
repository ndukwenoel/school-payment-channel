from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from ..database import Base


class School(Base):
    __tablename__ = "schools"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    address = Column(String)
    contact_email = Column(String)
    contact_phone = Column(String, nullable=True)
    logo_url = Column(String, nullable=True)
    allowed_installment_options = Column(String, default="2,3,4")
    enable_late_fees = Column(Boolean, default=False)
    late_fee_percentage = Column(Float, default=0.0)
    late_fee_grace_period_days = Column(Integer, default=0)
    status = Column(String, default="active") # active, suspended
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    subscription_plan = Column(String, nullable=True)
    subscription_due_date = Column(DateTime, nullable=True)
    modules_enabled = Column(String, default='["academics", "finance", "hr", "parent_portal"]')
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

class ClassRoom(Base):
    __tablename__ = "classrooms"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g. "Grade 10 - Blue"
    section = Column(String, nullable=True) # e.g. "A", "B"
    school_id = Column(Integer, ForeignKey("schools.id"))
    school = relationship("School", back_populates="classrooms")
    students = relationship("Student", back_populates="classroom")
    virtual_accounts = relationship("VirtualAccount", back_populates="classroom")

class Subject(Base):
    __tablename__ = "subjects"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g. "Mathematics"
    code = Column(String) # e.g. "MATH101"
    school_id = Column(Integer, ForeignKey("schools.id"))
    school = relationship("School", back_populates="subjects")

class PlatformInvoice(Base):
    __tablename__ = "platform_invoices"
    id = Column(Integer, primary_key=True, index=True)
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=False)
    amount_due = Column(Float, nullable=False)
    status = Column(String, default="unpaid") # unpaid, paid
    billing_period = Column(String) # e.g. 'August 2026'
    due_date = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    school = relationship("School")

class SystemSettings(Base):
    __tablename__ = "system_settings"
    id = Column(Integer, primary_key=True, index=True)
    paystack_public_key = Column(String, nullable=True)
    paystack_secret_key = Column(String, nullable=True)
    platform_fee_percentage = Column(Float, default=1.5)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
