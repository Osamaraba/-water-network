from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.geo import point, polygon
from app.database import Base

class Incident(Base):
    __tablename__ = "incidents"

    incident_id = Column(Integer, primary_key=True, index=True)
    incident_number = Column(String(50), unique=True, nullable=False, index=True)
    incident_type = Column(String(50), nullable=False)
    priority = Column(String(20), default="medium")
    title = Column(String(200), nullable=False)
    description = Column(Text)
    location = Column(point())
    location_address = Column(Text)
    status = Column(String(30), default="new")
    created_by = Column(Integer, ForeignKey("employees.employee_id"), nullable=False)
    assigned_team_id = Column(Integer)
    assigned_employee_id = Column(Integer, ForeignKey("employees.employee_id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    accepted_at = Column(DateTime(timezone=True))
    arrived_at = Column(DateTime(timezone=True))
    started_at = Column(DateTime(timezone=True))
    completed_at = Column(DateTime(timezone=True))
    verified_at = Column(DateTime(timezone=True))
    closed_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    status_history = relationship("IncidentStatusHistory", back_populates="incident", cascade="all, delete-orphan")
    photos = relationship("IncidentPhoto", back_populates="incident", cascade="all, delete-orphan")

class IncidentStatusHistory(Base):
    __tablename__ = "incident_status_history"

    history_id = Column(Integer, primary_key=True, index=True)
    incident_id = Column(Integer, ForeignKey("incidents.incident_id", ondelete="CASCADE"), nullable=False)
    old_status = Column(String(30))
    new_status = Column(String(30), nullable=False)
    changed_by = Column(Integer, ForeignKey("employees.employee_id"))
    notes = Column(Text)
    location = Column(point())
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    incident = relationship("Incident", back_populates="status_history")

class IncidentPhoto(Base):
    __tablename__ = "incident_photos"

    photo_id = Column(Integer, primary_key=True, index=True)
    incident_id = Column(Integer, ForeignKey("incidents.incident_id", ondelete="CASCADE"), nullable=False)
    employee_id = Column(Integer, ForeignKey("employees.employee_id"), nullable=False)
    photo_url = Column(Text, nullable=False)
    photo_type = Column(String(30), nullable=False)
    description = Column(Text)
    location = Column(point())
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    incident = relationship("Incident", back_populates="photos")
