from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
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
    fees = relationship("Fee", back_populates="student")

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
    payment_date = Column(DateTime, default=datetime.utcnow)
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
    sent_at = Column(DateTime, default=datetime.utcnow)
    status = Column(String, default="sent") # sent, failed

# Re-defining Fee to include discount relationship
# Note: In a real migration we would use Alembic. Here we are editing the file directly for initial setup.

