from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field
from datetime import date, time as dtime, datetime
from typing import Optional, List

from app.database import get_db
from app.models.employee import Employee
from app.models.report import TaskReport, TaskReportItem
from app.routers.auth import get_current_employee, RequirePermission, PRIVILEGED_ROLE_IDS, scope_by_department
from app.utils.response import success_response

router = APIRouter(prefix="/reports", tags=["Reports"])


class ReportItemIn(BaseModel):
    work_description: str = Field(..., min_length=1)
    work_date: date
    work_time: str  # HH:MM
    quantity: Optional[float] = None
    notes: Optional[str] = None


class TaskReportCreate(BaseModel):
    report_date: date
    incident_id: Optional[int] = None
    log_id: Optional[int] = None
    items: List[ReportItemIn]


def _parse_time(value: str) -> dtime:
    try:
        return datetime.strptime(value, "%H:%M").time()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid time format, expected HH:MM")


@router.post("/task")
async def create_task_report(
    request: TaskReportCreate,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("report.create"))
):
    report = TaskReport(
        employee_id=current_employee.employee_id,
        incident_id=request.incident_id,
        log_id=request.log_id,
        report_date=request.report_date,
    )
    db.add(report)
    db.commit()
    db.refresh(report)

    for item in request.items:
        db.add(TaskReportItem(
            report_id=report.report_id,
            work_description=item.work_description,
            work_date=item.work_date,
            work_time=_parse_time(item.work_time),
            quantity=item.quantity,
            notes=item.notes,
        ))
    db.commit()
    db.refresh(report)

    return success_response(data={
        "report_id": report.report_id,
        "items_count": len(report.items),
    }, message="Task report submitted")


@router.get("/task/mine")
async def my_task_reports(
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    reports = db.query(TaskReport).filter(
        TaskReport.employee_id == current_employee.employee_id
    ).order_by(TaskReport.report_date.desc()).all()
    return success_response(data=[_serialize(r) for r in reports])


@router.get("/task")
async def list_task_reports(
    employee_id: Optional[int] = None,
    report_date: Optional[date] = None,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("report.view"))
):
    query = db.query(TaskReport)
    allowed_ids = scope_by_department(db.query(Employee).filter(Employee.status == "active"), current_employee)
    allowed_ids = [e.employee_id for e in allowed_ids.all()] if current_employee.role_id not in PRIVILEGED_ROLE_IDS else None

    if allowed_ids is not None:
        query = query.filter(TaskReport.employee_id.in_(allowed_ids))
    if employee_id:
        if allowed_ids is not None and employee_id not in allowed_ids:
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        query = query.filter(TaskReport.employee_id == employee_id)
    if report_date:
        query = query.filter(TaskReport.report_date == report_date)

    reports = query.order_by(TaskReport.report_date.desc()).all()
    return success_response(data=[_serialize(r) for r in reports])


@router.get("/task/{report_id}")
async def get_task_report(
    report_id: int,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("report.view"))
):
    report = db.query(TaskReport).filter(TaskReport.report_id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    if current_employee.role_id not in PRIVILEGED_ROLE_IDS and report.employee_id != current_employee.employee_id:
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    return success_response(data=_serialize(report))


def _serialize(report: TaskReport) -> dict:
    return {
        "report_id": report.report_id,
        "employee_id": report.employee_id,
        "incident_id": report.incident_id,
        "log_id": report.log_id,
        "report_date": report.report_date.isoformat() if report.report_date else None,
        "status": report.status,
        "created_at": report.created_at.isoformat() if report.created_at else None,
        "items": [{
            "item_id": i.item_id,
            "work_description": i.work_description,
            "work_date": i.work_date.isoformat() if i.work_date else None,
            "work_time": i.work_time.strftime("%H:%M") if i.work_time else None,
            "quantity": i.quantity,
            "notes": i.notes,
        } for i in report.items],
    }
