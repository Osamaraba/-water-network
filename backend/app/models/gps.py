from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.geo import point, polygon
from app.database import Base
import uuid

class GpsSession(Base):
    __tablename__ = "gps_sessions"

    session_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    employee_id = Column(Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False)
    device_id = Column(Integer, ForeignKey("employee_devices.device_id"))
    started_at = Column(DateTime(timezone=True), nullable=False)
    ended_at = Column(DateTime(timezone=True))
    start_location = Column(point())
    end_location = Column(point())
    total_distance_meters = Column(Float, default=0)
    total_points = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    employee = relationship("Employee", back_populates="gps_sessions")
    telemetry = relationship("GpsTelemetry", back_populates="session", cascade="all, delete-orphan")

class GpsTelemetry(Base):
    __tablename__ = "gps_telemetry"

    telemetry_id = Column(Integer, primary_key=True, index=True)
    session_id = Column(UUID(as_uuid=True), ForeignKey("gps_sessions.session_id", ondelete="CASCADE"), nullable=False)
    employee_id = Column(Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False)
    coordinates = Column(point(), nullable=False)
    accuracy = Column(Float)
    altitude = Column(Float)
    speed = Column(Float)
    heading = Column(Float)
    battery_level = Column(Integer)
    network_type = Column(String(20))
    recorded_at = Column(DateTime(timezone=True), nullable=False)
    server_received_at = Column(DateTime(timezone=True), server_default=func.now())
    is_synced = Column(Boolean, default=True)

    session = relationship("GpsSession", back_populates="telemetry")
