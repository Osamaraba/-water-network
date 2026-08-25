from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_
from pydantic import BaseModel, Field
from datetime import time as dtime
from typing import Optional, List

from app.database import get_db
from app.models.employee import Employee
from app.models.shift import Shift, ShiftAssignment
from app.routers.auth import get_current_employee, RequirePermission, PRIVILEGED_ROLE_IDS, scope_by_department
from app.utils.response import success_response

router = APIRouter(prefix="/shifts", tags=["Shifts"])


def _parse_time(value: str) -> dtime:
    try:
        return datetime.strptime(value, "%H:%M").time()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid time format, expected HH:MM")


from datetime import datetime


class ShiftCreate(BaseModel):
    shift_name: str = Field(..., min_length=1, max_length=50)
    department: Optional[str] = None
    start_time: str
    end_time: str
    grace_minutes: int = 15
    is_night_shift: bool = False


class ShiftUpdate(BaseModel):
    shift_name: Optional[str] = None
    department: Optional[str] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    grace_minutes: Optional[int] = None
    is_night_shift: Optional[bool] = None
    is_active: Optional[bool] = None


@router.post("")
async def create_shift(
    request: ShiftCreate,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("shift.manage"))
):
    shift = Shift(
        shift_name=request.shift_name,
        department=request.department,
        start_time=_parse_time(request.start_time),
        end_time=_parse_time(request.end_time),
        grace_minutes=request.grace_minutes,
        is_night_shift=request.is_night_shift,
        created_by=current_employee.employee_id,
    )
    db.add(shift)
    db.commit()
    db.refresh(shift)
    return success_response(data={"shift_id": shift.shift_id}, message="Shift created")


@router.get("")
async def list_shifts(
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("shift.view"))
):
    query = db.query(Shift)
    if current_employee.role_id not in PRIVILEGED_ROLE_IDS:
        query = query.filter(
            or_(Shift.department == current_employee.department, Shift.department.is_(None))
        )
    shifts = query.order_by(Shift.department, Shift.start_time).all()
    return success_response(data=[{
        "shift_id": s.shift_id,
        "shift_name": s.shift_name,
        "department": s.department,
        "start_time": s.start_time.strftime("%H:%M") if s.start_time else None,
        "end_time": s.end_time.strftime("%H:%M") if s.end_time else None,
        "grace_minutes": s.grace_minutes,
        "is_night_shift": s.is_night_shift,
        "is_active": s.is_active,
    } for s in shifts])


@router.get("/{shift_id}")
async def get_shift(
    shift_id: int,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("shift.view"))
):
    shift = db.query(Shift).filter(Shift.shift_id == shift_id).first()
    if not shift:
        raise HTTPException(status_code=404, detail="Shift not found")
    return success_response(data={
        "shift_id": shift.shift_id,
        "shift_name": shift.shift_name,
        "department": shift.department,
        "start_time": shift.start_time.strftime("%H:%M") if shift.start_time else None,
        "end_time": shift.end_time.strftime("%H:%M") if shift.end_time else None,
        "grace_minutes": shift.grace_minutes,
        "is_night_shift": shift.is_night_shift,
        "is_active": shift.is_active,
    })


@router.put("/{shift_id}")
async def update_shift(
    shift_id: int,
    request: ShiftUpdate,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("shift.manage"))
):
    shift = db.query(Shift).filter(Shift.shift_id == shift_id).first()
    if not shift:
        raise HTTPException(status_code=404, detail="Shift not found")

    if request.shift_name is not None:
        shift.shift_name = request.shift_name
    if request.department is not None:
        shift.department = request.department
    if request.start_time is not None:
        shift.start_time = _parse_time(request.start_time)
    if request.end_time is not None:
        shift.end_time = _parse_time(request.end_time)
    if request.grace_minutes is not None:
        shift.grace_minutes = request.grace_minutes
    if request.is_night_shift is not None:
        shift.is_night_shift = request.is_night_shift
    if request.is_active is not None:
        shift.is_active = request.is_active

    db.commit()
    return success_response(message="Shift updated")


@router.delete("/{shift_id}")
async def delete_shift(
    shift_id: int,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("shift.manage"))
):
    shift = db.query(Shift).filter(Shift.shift_id == shift_id).first()
    if not shift:
        raise HTTPException(status_code=404, detail="Shift not found")
    shift.is_active = False
    db.commit()
    return success_response(message="Shift deactivated")


@router.post("/{shift_id}/apply")
async def apply_shift_to_team(
    shift_id: int,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("shift.manage"))
):
    """Apply this shift to every active employee in its department (the team)."""
    shift = db.query(Shift).filter(Shift.shift_id == shift_id, Shift.is_active == True).first()
    if not shift:
        raise HTTPException(status_code=404, detail="Shift not found")
    if not shift.department:
        raise HTTPException(status_code=400, detail="Shift has no department/team assigned")

    employees = db.query(Employee).filter(
        Employee.department == shift.department,
        Employee.status == "active"
    ).all()
    for emp in employees:
        emp.shift_start = shift.start_time
        emp.shift_end = shift.end_time
    db.commit()

    return success_response(data={
        "department": shift.department,
        "updated_employees": len(employees),
        "start_time": shift.start_time.strftime("%H:%M"),
        "end_time": shift.end_time.strftime("%H:%M"),
    }, message="Shift applied to team")
