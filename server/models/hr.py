from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from ..database import Base


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
