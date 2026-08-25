from sqlalchemy import Column, Integer, String, Boolean, Time, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class Shift(Base):
    __tablename__ = "shifts"

    shift_id = Column(Integer, primary_key=True, index=True)
    shift_name = Column(String(50), nullable=False)
    department = Column(String(50))  # team/department this shift belongs to
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    grace_minutes = Column(Integer, default=15)
    is_night_shift = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    created_by = Column(Integer, ForeignKey("employees.employee_id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    creator = relationship("Employee")


class ShiftAssignment(Base):
    __tablename__ = "shift_assignments"

    assignment_id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False)
    shift_id = Column(Integer, ForeignKey("shifts.shift_id", ondelete="CASCADE"), nullable=False)
    effective_from = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    effective_to = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
