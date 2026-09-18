from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from ..database import Base


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    full_name = Column(String)
    role = Column(String, default="parent") # parent, admin, school_admin
    is_active = Column(Boolean, default=True)
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)
    credit_balance = Column(Float, default=0.0) # Used for overpayments/advance payments
    auto_pay_enabled = Column(Boolean, default=False)
    students = relationship("Student", back_populates="parent")
    school = relationship("School", back_populates="users")

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
