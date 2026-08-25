from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.geo import point, polygon
from app.database import Base
import uuid

class AttendanceLog(Base):
    __tablename__ = "attendance_logs"

    log_id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False)
    device_id = Column(Integer, ForeignKey("employee_devices.device_id"))
    session_id = Column(UUID(as_uuid=True), default=uuid.uuid4)
    check_in_time = Column(DateTime(timezone=True), nullable=False)
    check_out_time = Column(DateTime(timezone=True))
    check_in_location = Column(point(), nullable=False)
    check_out_location = Column(point())
    check_in_accuracy = Column(Float)
    check_out_accuracy = Column(Float)
    check_in_image_url = Column(Text)
    check_out_image_url = Column(Text)
    is_offline_sync = Column(Boolean, default=False)
    client_transaction_id = Column(String(100))
    trust_score = Column(Integer)
    trust_status = Column(String(20), default="valid")
    trust_reasons = Column(JSONB)
    server_check_in_time = Column(DateTime(timezone=True), server_default=func.now())
    server_check_out_time = Column(DateTime(timezone=True))
    device_time_offset_seconds = Column(Integer)
    is_mock_location_detected = Column(Boolean, default=False)
    overtime_hours = Column(Float, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    employee = relationship("Employee", back_populates="attendance_logs")

class AttendanceEvent(Base):
    __tablename__ = "attendance_events"

    event_id = Column(Integer, primary_key=True, index=True)
    log_id = Column(Integer, ForeignKey("attendance_logs.log_id", ondelete="CASCADE"))
    employee_id = Column(Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False)
    event_type = Column(String(50), nullable=False)
    event_data = Column(JSONB)
    location = Column(point())
    recorded_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class AttendanceEvidence(Base):
    __tablename__ = "attendance_evidence"

    evidence_id = Column(Integer, primary_key=True, index=True)
    log_id = Column(Integer, ForeignKey("attendance_logs.log_id", ondelete="CASCADE"), nullable=False)
    evidence_type = Column(String(20), nullable=False)
    image_url = Column(Text, nullable=False)
    image_hash = Column(String(256), nullable=False)
    file_size_bytes = Column(Integer)
    meta_data = Column(JSONB)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
