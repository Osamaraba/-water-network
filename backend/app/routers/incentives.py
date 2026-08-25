from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func as sqlfunc
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional

from app.database import get_db
from app.models.employee import Employee
from app.models.evaluation import PerformanceEvaluation
from app.models.incentive import Incentive
from app.routers.auth import get_current_employee, RequirePermission, PRIVILEGED_ROLE_IDS
from app.utils.response import success_response

router = APIRouter(prefix="/incentives", tags=["Incentives"])


class IncentiveCompute(BaseModel):
    employee_id: int
    period_start: str  # ISO datetime
    period_end: str    # ISO datetime


class IncentiveApprove(BaseModel):
    incentive_amount: float
    status: str = "approved"  # approved/rejected


def _parse(dt: str) -> datetime:
    try:
        return datetime.fromisoformat(dt.replace("Z", "+00:00"))
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid datetime, expected ISO format")


def _serialize(inc: Incentive) -> dict:
    return {
        "incentive_id": inc.incentive_id,
        "employee_id": inc.employee_id,
        "period_start": inc.period_start.isoformat() if inc.period_start else None,
        "period_end": inc.period_end.isoformat() if inc.period_end else None,
        "avg_speed": inc.avg_speed,
        "avg_accuracy": inc.avg_accuracy,
        "performance_score": inc.performance_score,
        "incentive_amount": inc.incentive_amount,
        "status": inc.status,
        "reviewed_by": inc.reviewed_by,
        "reviewed_at": inc.reviewed_at.isoformat() if inc.reviewed_at else None,
    }


@router.post("/compute")
async def compute_incentive(
    request: IncentiveCompute,
    db: Session = Depends(get_db),
    current: Employee = Depends(RequirePermission("incentive.manage")),
):
    start = _parse(request.period_start)
    end = _parse(request.period_end)
    emp = db.query(Employee).filter(Employee.employee_id == request.employee_id).first()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")

    row = db.query(
        sqlfunc.avg(PerformanceEvaluation.speed_score),
        sqlfunc.avg(PerformanceEvaluation.accuracy_score),
        sqlfunc.count(PerformanceEvaluation.evaluation_id),
    ).filter(
        PerformanceEvaluation.employee_id == request.employee_id,
        PerformanceEvaluation.created_at >= start,
        PerformanceEvaluation.created_at <= end,
    ).first()

    avg_speed = float(row[0]) if row[0] is not None else 0.0
    avg_accuracy = float(row[1]) if row[1] is not None else 0.0
    performance_score = round((avg_speed + avg_accuracy) / 2, 2)

    existing = db.query(Incentive).filter(
        Incentive.employee_id == request.employee_id,
        Incentive.period_start == start,
        Incentive.period_end == end,
    ).first()

    if existing:
        existing.avg_speed = avg_speed
        existing.avg_accuracy = avg_accuracy
        existing.performance_score = performance_score
    else:
        existing = Incentive(
            employee_id=request.employee_id,
            period_start=start,
            period_end=end,
            avg_speed=avg_speed,
            avg_accuracy=avg_accuracy,
            performance_score=performance_score,
            status="pending",
        )
        db.add(existing)
    db.commit()
    db.refresh(existing)
    return success_response(data=_serialize(existing), message="Incentive computed")


@router.get("")
async def list_incentives(
    employee_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current: Employee = Depends(RequirePermission("incentive.view")),
):
    query = db.query(Incentive)
    if current.role_id not in PRIVILEGED_ROLE_IDS:
        query = query.filter(Incentive.employee_id == current.employee_id)
    if employee_id is not None:
        if current.role_id not in PRIVILEGED_ROLE_IDS and employee_id != current.employee_id:
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        query = query.filter(Incentive.employee_id == employee_id)
    incentives = query.order_by(Incentive.period_end.desc()).all()
    return success_response(data=[_serialize(i) for i in incentives])


@router.post("/{incentive_id}/approve")
async def approve_incentive(
    incentive_id: int,
    request: IncentiveApprove,
    db: Session = Depends(get_db),
    current: Employee = Depends(RequirePermission("incentive.manage")),
):
    if request.status not in ("approved", "rejected"):
        raise HTTPException(status_code=400, detail="status must be approved or rejected")
    inc = db.query(Incentive).filter(Incentive.incentive_id == incentive_id).first()
    if not inc:
        raise HTTPException(status_code=404, detail="Incentive not found")
    inc.incentive_amount = request.incentive_amount
    inc.status = request.status
    inc.reviewed_by = current.employee_id
    inc.reviewed_at = datetime.utcnow()
    db.commit()
    db.refresh(inc)
    return success_response(data=_serialize(inc), message="Incentive reviewed")
