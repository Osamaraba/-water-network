from sqlalchemy import Column, Integer, ForeignKey, Text, DateTime
from sqlalchemy.sql import func
from app.database import Base


class PerformanceEvaluation(Base):
    __tablename__ = "performance_evaluations"

    evaluation_id = Column(Integer, primary_key=True, index=True)
    evaluator_id = Column(Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False)
    employee_id = Column(Integer, ForeignKey("employees.employee_id", ondelete="CASCADE"), nullable=False)
    task_report_id = Column(Integer, ForeignKey("task_reports.report_id", ondelete="SET NULL"), nullable=True)
    speed_score = Column(Integer, nullable=False)  # 1-5
    accuracy_score = Column(Integer, nullable=False)  # 1-5
    comment = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
