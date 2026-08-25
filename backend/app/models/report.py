from sqlalchemy import Column, Integer, String, Text, Float, Date, Time, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class TaskReport(Base):
    __tablename__ = "task_reports"

    report_id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False)
    incident_id = Column(Integer, ForeignKey("incidents.incident_id", ondelete="CASCADE"), nullable=True)
    log_id = Column(Integer, ForeignKey("attendance_logs.log_id", ondelete="SET NULL"), nullable=True)
    report_date = Column(Date, nullable=False)
    status = Column(String(20), default="submitted")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    employee = relationship("Employee")
    items = relationship("TaskReportItem", back_populates="report", cascade="all, delete-orphan")


class TaskReportItem(Base):
    __tablename__ = "task_report_items"

    item_id = Column(Integer, primary_key=True, index=True)
    report_id = Column(Integer, ForeignKey("task_reports.report_id", ondelete="CASCADE"), nullable=False)
    work_description = Column(Text, nullable=False)
    work_date = Column(Date, nullable=False)
    work_time = Column(Time, nullable=False)
    quantity = Column(Float)
    notes = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    report = relationship("TaskReport", back_populates="items")
