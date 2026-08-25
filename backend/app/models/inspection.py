from sqlalchemy import Column, Integer, ForeignKey, String, Text, DateTime, Float
from sqlalchemy.sql import func
from app.database import Base


class InspectionTour(Base):
    __tablename__ = "inspection_tours"

    tour_id = Column(Integer, primary_key=True, index=True)
    distributor_id = Column(Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False)
    assigned_by = Column(Integer, ForeignKey("employees.employee_id"), nullable=False)
    recipient_manager_id = Column(Integer, ForeignKey("employees.employee_id"), nullable=False)
    title = Column(String(150))
    notes = Column(Text)
    scheduled_at = Column(DateTime(timezone=True))
    started_at = Column(DateTime(timezone=True))
    ended_at = Column(DateTime(timezone=True))
    status = Column(String(20), default="assigned")  # assigned/in_progress/completed/sent
    sent_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


class InspectionTourPoint(Base):
    __tablename__ = "inspection_tour_points"

    point_id = Column(Integer, primary_key=True, index=True)
    tour_id = Column(Integer, ForeignKey("inspection_tours.tour_id", ondelete="CASCADE"), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    recorded_at = Column(DateTime(timezone=True), server_default=func.now())
