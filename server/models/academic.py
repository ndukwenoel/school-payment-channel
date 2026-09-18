from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from ..database import Base


class CourseTest(Base):
    __tablename__ = "course_tests"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)         # e.g. "Test 1", "Mid-Term Exam", "Final Exam"
    test_type = Column(String)     # "test", "exam", "ca", "quiz", "assignment"
    max_score = Column(Float, default=100.0)
    weight_percentage = Column(Float, nullable=True)  # e.g. 30 (for 30% of final grade)
    term = Column(String)          # e.g. "First Term"
    academic_year = Column(String) # e.g. "2025/2026"
    date_administered = Column(DateTime, nullable=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"))
    classroom_id = Column(Integer, ForeignKey("classrooms.id"))
    school_id = Column(Integer, ForeignKey("schools.id"))
    created_by = Column(Integer, ForeignKey("users.id"))  # teacher
    subject = relationship("Subject")
    classroom = relationship("ClassRoom")
    school = relationship("School")
    teacher = relationship("User")
    results = relationship("TestResult", back_populates="course_test")

class TestResult(Base):
    __tablename__ = "test_results"
    id = Column(Integer, primary_key=True, index=True)
    score = Column(Float)
    remarks = Column(String, nullable=True)  # e.g. "Excellent", "Needs improvement"
    test_id = Column(Integer, ForeignKey("course_tests.id"))
    student_id = Column(Integer, ForeignKey("students.id"))
    school_id = Column(Integer, ForeignKey("schools.id"))
    recorded_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    course_test = relationship("CourseTest", back_populates="results")
    student = relationship("Student", back_populates="test_results")

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
