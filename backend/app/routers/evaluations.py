from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func as sqlfunc
from pydantic import BaseModel, Field
from typing import Optional

from app.database import get_db
from app.models.employee import Employee
from app.models.evaluation import PerformanceEvaluation
from app.routers.auth import get_current_employee, RequirePermission, PRIVILEGED_ROLE_IDS
from app.utils.response import success_response

router = APIRouter(prefix="/evaluations", tags=["Performance Evaluations"])


class EvaluationCreate(BaseModel):
    employee_id: int
    task_report_id: Optional[int] = None
    speed_score: int = Field(..., ge=1, le=5)
    accuracy_score: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None


def _serialize(e: PerformanceEvaluation) -> dict:
    return {
        "evaluation_id": e.evaluation_id,
        "evaluator_id": e.evaluator_id,
        "employee_id": e.employee_id,
        "task_report_id": e.task_report_id,
        "speed_score": e.speed_score,
        "accuracy_score": e.accuracy_score,
        "comment": e.comment,
        "created_at": e.created_at.isoformat() if e.created_at else None,
    }


@router.post("")
async def create_evaluation(
    request: EvaluationCreate,
    db: Session = Depends(get_db),
    current: Employee = Depends(RequirePermission("evaluation.create")),
):
    emp = db.query(Employee).filter(Employee.employee_id == request.employee_id).first()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")
    if request.task_report_id is not None:
        from app.models.report import TaskReport
        if not db.query(TaskReport).filter(TaskReport.report_id == request.task_report_id).first():
            raise HTTPException(status_code=404, detail="Task report not found")

    evaluation = PerformanceEvaluation(
        evaluator_id=current.employee_id,
        employee_id=request.employee_id,
        task_report_id=request.task_report_id,
        speed_score=request.speed_score,
        accuracy_score=request.accuracy_score,
        comment=request.comment,
    )
    db.add(evaluation)
    db.commit()
    db.refresh(evaluation)
    return success_response(data=_serialize(evaluation), message="Evaluation recorded")


@router.get("")
async def list_evaluations(
    employee_id: Optional[int] = None,
    period_from: Optional[str] = None,
    period_to: Optional[str] = None,
    db: Session = Depends(get_db),
    current: Employee = Depends(RequirePermission("evaluation.view")),
):
    query = db.query(PerformanceEvaluation)
    if current.role_id not in PRIVILEGED_ROLE_IDS:
        dept_ids = [r[0] for r in db.query(Employee.employee_id)
                    .filter(Employee.department == current.department).all()] or [-1]
        query = query.filter(
            (PerformanceEvaluation.employee_id.in_(dept_ids))
            | (PerformanceEvaluation.evaluator_id == current.employee_id)
        )
    if employee_id is not None:
        query = query.filter(PerformanceEvaluation.employee_id == employee_id)
    if period_from:
        query = query.filter(PerformanceEvaluation.created_at >= period_from)
    if period_to:
        query = query.filter(PerformanceEvaluation.created_at <= period_to)
    evals = query.order_by(PerformanceEvaluation.created_at.desc()).all()
    return success_response(data=[_serialize(e) for e in evals])


@router.get("/mine")
async def my_evaluations(
    db: Session = Depends(get_db),
    current: Employee = Depends(RequirePermission("evaluation.view")),
):
    evals = db.query(PerformanceEvaluation).filter(
        PerformanceEvaluation.employee_id == current.employee_id
    ).order_by(PerformanceEvaluation.created_at.desc()).all()
    return success_response(data=[_serialize(e) for e in evals])


@router.get("/employee/{employee_id}/summary")
async def employee_summary(
    employee_id: int,
    db: Session = Depends(get_db),
    current: Employee = Depends(RequirePermission("evaluation.view")),
):
    emp = db.query(Employee).filter(Employee.employee_id == employee_id).first()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")
    row = db.query(
        sqlfunc.avg(PerformanceEvaluation.speed_score),
        sqlfunc.avg(PerformanceEvaluation.accuracy_score),
        sqlfunc.count(PerformanceEvaluation.evaluation_id),
    ).filter(PerformanceEvaluation.employee_id == employee_id).first()

    avg_speed = float(row[0]) if row[0] is not None else None
    avg_accuracy = float(row[1]) if row[1] is not None else None
    count = row[2] or 0
    performance_score = round((avg_speed + avg_accuracy) / 2, 2) if avg_speed is not None else None
    return success_response(data={
        "employee_id": employee_id,
        "avg_speed": avg_speed,
        "avg_accuracy": avg_accuracy,
        "performance_score": performance_score,
        "evaluation_count": count,
    })
