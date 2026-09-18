from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from ..database import Base


class Student(Base):
    __tablename__ = "students"
    id = Column(Integer, primary_key=True, index=True)
    enrollment_number = Column(String, unique=True, index=True)
    full_name = Column(String)
    grade = Column(String)
    date_of_birth = Column(DateTime, nullable=True)
    gender = Column(String, nullable=True)
    profile_picture_url = Column(String, nullable=True)
    home_address = Column(String, nullable=True)
    emergency_contact_name = Column(String, nullable=True)
    emergency_contact_phone = Column(String, nullable=True)
    blood_group = Column(String, nullable=True)
    genotype = Column(String, nullable=True)
    allergies = Column(String, nullable=True)
    medical_conditions = Column(String, nullable=True)
    admission_date = Column(DateTime, nullable=True)
    status = Column(String, default="active") # active, suspended, graduated, transferred
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
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
    documents = relationship("StudentDocument", back_populates="student")
    test_results = relationship("TestResult", back_populates="student")

class StudentDocument(Base):
    __tablename__ = "student_documents"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    document_type = Column(String) # medical, academic, behavioral, identification, other
    file_url = Column(String)
    notes = Column(String, nullable=True)
    uploaded_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    student_id = Column(Integer, ForeignKey("students.id"))
    uploaded_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    student = relationship("Student", back_populates="documents")
    uploader = relationship("User")

class Attendance(Base):
    __tablename__ = "attendance"
    id = Column(Integer, primary_key=True, index=True)
    date = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    status = Column(String) # present, absent, late
    remarks = Column(String, nullable=True) # optional teacher notes
    student_id = Column(Integer, ForeignKey("students.id"))
    classroom_id = Column(Integer, ForeignKey("classrooms.id"), nullable=True)
    school_id = Column(Integer, ForeignKey("schools.id"))
    student = relationship("Student", back_populates="attendance_records")
    school = relationship("School", back_populates="attendance_records")
