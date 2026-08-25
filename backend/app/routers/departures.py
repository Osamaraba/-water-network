from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional

from app.database import get_db
from app.models.employee import Employee
from app.models.departure import Departure
from app.routers.auth import get_current_employee, RequirePermission
from app.utils.response import success_response

router = APIRouter(prefix="/departures", tags=["Departures"])


class DepartureCreateRequest(BaseModel):
    departure_type: str = Field(..., pattern="^(official|personal)$")
    departure_time: datetime
    return_time: datetime
    reason: Optional[str] = None


class DepartureReviewRequest(BaseModel):
    status: str = Field(..., pattern="^(approved|rejected)$")
    review_note: Optional[str] = None


def _serialize(d: Departure):
    return {
        "departure_id": d.departure_id,
        "employee_id": d.employee_id,
        "departure_type": d.departure_type,
        "departure_time": d.departure_time.isoformat() if d.departure_time else None,
        "return_time": d.return_time.isoformat() if d.return_time else None,
        "reason": d.reason,
        "status": d.status,
        "review_note": d.review_note,
        "reviewed_at": d.reviewed_at.isoformat() if d.reviewed_at else None,
        "created_at": d.created_at.isoformat() if d.created_at else None,
    }


@router.post("/")
async def create_departure(
    request: DepartureCreateRequest,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee),
):
    if request.return_time <= request.departure_time:
        raise HTTPException(status_code=400, detail="Return time must be after departure time")

    departure = Departure(
        employee_id=current_employee.employee_id,
        departure_type=request.departure_type,
        departure_time=request.departure_time,
        return_time=request.return_time,
        reason=request.reason,
        status="pending",
    )
    db.add(departure)
    db.commit()
    db.refresh(departure)
    return success_response(
        data={"departure_id": departure.departure_id, "status": departure.status},
        message="Departure request submitted",
    )


@router.get("/me")
async def my_departures(
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee),
):
    departures = (
        db.query(Departure)
        .filter(Departure.employee_id == current_employee.employee_id)
        .order_by(Departure.created_at.desc())
        .all()
    )
    return success_response(data=[_serialize(d) for d in departures])


@router.get("/")
async def list_departures(
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("departure.hr_review")),
):
    query = db.query(Departure)
    if status:
        query = query.filter(Departure.status == status)
    departures = query.order_by(Departure.created_at.desc()).all()

    result = []
    for d in departures:
        emp = db.query(Employee).filter(Employee.employee_id == d.employee_id).first()
        item = _serialize(d)
        item["employee_name"] = emp.full_name if emp else None
        item["employee_number"] = emp.employee_number if emp else None
        result.append(item)
    return success_response(data=result)


@router.post("/{departure_id}/review")
async def review_departure(
    departure_id: int,
    request: DepartureReviewRequest,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("departure.hr_review")),
):
    departure = db.query(Departure).filter(Departure.departure_id == departure_id).first()
    if not departure:
        raise HTTPException(status_code=404, detail="Departure not found")
    if departure.status != "pending":
        raise HTTPException(status_code=400, detail="Only pending departures can be reviewed")

    departure.status = request.status
    departure.reviewed_by = current_employee.employee_id
    departure.review_note = request.review_note
    departure.reviewed_at = datetime.utcnow()
    db.commit()
    return success_response(data={"departure_id": departure_id, "status": departure.status})
