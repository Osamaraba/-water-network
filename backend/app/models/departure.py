from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.database import Base


class Departure(Base):
    __tablename__ = "departures"

    departure_id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, ForeignKey("employees.employee_id"), nullable=False, index=True)
    departure_type = Column(String(20), nullable=False)  # 'official' | 'personal'
    departure_time = Column(DateTime(timezone=True), nullable=False)
    return_time = Column(DateTime(timezone=True), nullable=False)
    reason = Column(Text)
    status = Column(String(20), default="pending")  # pending | approved | rejected
    reviewed_by = Column(Integer, ForeignKey("employees.employee_id"))
    review_note = Column(Text)
    reviewed_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
