from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from ..database import Base


class InventoryItem(Base):
    __tablename__ = "inventory_items"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g. "Whiteboard Marker"
    category = Column(String) # e.g. "Stationery", "Lab"
    quantity = Column(Integer, default=0)
    unit_price = Column(Float, nullable=True)
    is_for_sale = Column(Boolean, default=False)
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

class NotificationLog(Base):
    __tablename__ = "notification_logs"
    id = Column(Integer, primary_key=True, index=True)
    recipient_email = Column(String)
    subject = Column(String)
    message = Column(String)
    sent_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    status = Column(String, default="sent") # sent, failed
    school_id = Column(Integer, ForeignKey("schools.id"), nullable=True)

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
