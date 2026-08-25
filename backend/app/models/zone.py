from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.geo import point, polygon
from app.database import Base

class WorkZone(Base):
    __tablename__ = "work_zones"

    zone_id = Column(Integer, primary_key=True, index=True)
    zone_name = Column(String(100), nullable=False)
    zone_type = Column(String(20), nullable=False)
    center_point = Column(point())
    radius_meters = Column(Float)
    boundary_polygon = Column(polygon())
    description = Column(Text)
    is_active = Column(Boolean, default=True)
    created_by = Column(Integer, ForeignKey("employees.employee_id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    assignments = relationship("ZoneAssignment", back_populates="zone", cascade="all, delete-orphan")

class ZoneAssignment(Base):
    __tablename__ = "zone_assignments"

    assignment_id = Column(Integer, primary_key=True, index=True)
    zone_id = Column(Integer, ForeignKey("work_zones.zone_id", ondelete="CASCADE"), nullable=False)
    employee_id = Column(Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False)
    assigned_from = Column(DateTime(timezone=True), nullable=False)
    assigned_to = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    zone = relationship("WorkZone", back_populates="assignments")
