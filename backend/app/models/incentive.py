from sqlalchemy import Column, Integer, ForeignKey, Float, DateTime, String
from sqlalchemy.sql import func
from app.database import Base


class Incentive(Base):
    __tablename__ = "incentives"

    incentive_id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False)
    period_start = Column(DateTime(timezone=True), nullable=False)
    period_end = Column(DateTime(timezone=True), nullable=False)
    avg_speed = Column(Float)
    avg_accuracy = Column(Float)
    performance_score = Column(Float)
    incentive_amount = Column(Float)
    status = Column(String(20), default="pending")  # pending/approved/rejected
    reviewed_by = Column(Integer, ForeignKey("employees.employee_id"), nullable=True)
    reviewed_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
