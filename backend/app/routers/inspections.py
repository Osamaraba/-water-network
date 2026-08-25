from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional

from app.database import get_db
from app.models.employee import Employee
from app.models.inspection import InspectionTour, InspectionTourPoint
from app.routers.auth import get_current_employee, RequirePermission
from app.utils.response import success_response

router = APIRouter(prefix="/inspections", tags=["Inspection Tours"])

WATER_DISTRIBUTOR_ROLE_ID = 12


class InspectionAssign(BaseModel):
    distributor_id: int
    recipient_manager_id: int
    title: Optional[str] = None
    notes: Optional[str] = None
    scheduled_at: Optional[str] = None  # ISO datetime


class InspectionPoint(BaseModel):
    latitude: float
    longitude: float
    recorded_at: Optional[str] = None  # ISO datetime


def _parse(dt: Optional[str]) -> Optional[datetime]:
    if not dt:
        return None
    try:
        return datetime.fromisoformat(dt.replace("Z", "+00:00"))
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid datetime, expected ISO format")


def _serialize(tour: InspectionTour) -> dict:
    return {
        "tour_id": tour.tour_id,
        "distributor_id": tour.distributor_id,
        "assigned_by": tour.assigned_by,
        "recipient_manager_id": tour.recipient_manager_id,
        "title": tour.title,
        "notes": tour.notes,
        "scheduled_at": tour.scheduled_at.isoformat() if tour.scheduled_at else None,
        "started_at": tour.started_at.isoformat() if tour.started_at else None,
        "ended_at": tour.ended_at.isoformat() if tour.ended_at else None,
        "status": tour.status,
        "sent_at": tour.sent_at.isoformat() if tour.sent_at else None,
    }


@router.post("")
async def assign_inspection(
    request: InspectionAssign,
    db: Session = Depends(get_db),
    current: Employee = Depends(RequirePermission("inspection.create")),
):
    distributor = db.query(Employee).filter(Employee.employee_id == request.distributor_id).first()
    if not distributor:
        raise HTTPException(status_code=404, detail="Distributor not found")
    if distributor.role_id != WATER_DISTRIBUTOR_ROLE_ID:
        raise HTTPException(status_code=400, detail="Target employee is not a water distributor")

    recipient = db.query(Employee).filter(Employee.employee_id == request.recipient_manager_id).first()
    if not recipient:
        raise HTTPException(status_code=404, detail="Recipient manager not found")

    tour = InspectionTour(
        distributor_id=request.distributor_id,
        assigned_by=current.employee_id,
        recipient_manager_id=request.recipient_manager_id,
        title=request.title,
        notes=request.notes,
        scheduled_at=_parse(request.scheduled_at) or datetime.utcnow(),
        status="assigned",
    )
    db.add(tour)
    db.commit()
    db.refresh(tour)
    return success_response(data=_serialize(tour), message="Inspection tour assigned")


@router.get("")
async def list_inspections(
    db: Session = Depends(get_db),
    current: Employee = Depends(RequirePermission("inspection.view")),
):
    query = db.query(InspectionTour)
    if current.role_id == WATER_DISTRIBUTOR_ROLE_ID:
        query = query.filter(InspectionTour.distributor_id == current.employee_id)
    else:
        query = query.filter(
            (InspectionTour.assigned_by == current.employee_id)
            | (InspectionTour.recipient_manager_id == current.employee_id)
        )
    tours = query.order_by(InspectionTour.created_at.desc()).all()
    return success_response(data=[_serialize(t) for t in tours])


@router.get("/{tour_id}/points")
async def get_tour_points(
    tour_id: int,
    db: Session = Depends(get_db),
    current: Employee = Depends(RequirePermission("inspection.view")),
):
    points = db.query(InspectionTourPoint).filter(
        InspectionTourPoint.tour_id == tour_id
    ).order_by(InspectionTourPoint.recorded_at).all()
    return success_response(data=[{
        "point_id": p.point_id,
        "latitude": p.latitude,
        "longitude": p.longitude,
        "recorded_at": p.recorded_at.isoformat() if p.recorded_at else None,
    } for p in points])


@router.post("/{tour_id}/start")
async def start_inspection(
    tour_id: int,
    db: Session = Depends(get_db),
    current: Employee = Depends(RequirePermission("inspection.update")),
):
    tour = db.query(InspectionTour).filter(InspectionTour.tour_id == tour_id).first()
    if not tour:
        raise HTTPException(status_code=404, detail="Tour not found")
    if tour.distributor_id != current.employee_id:
        raise HTTPException(status_code=403, detail="Only the assigned distributor can start this tour")
    if tour.status not in ("assigned", "in_progress"):
        raise HTTPException(status_code=400, detail="Tour cannot be started")
    tour.status = "in_progress"
    tour.started_at = datetime.utcnow()
    db.commit()
    db.refresh(tour)
    return success_response(data=_serialize(tour), message="Inspection tour started")


@router.post("/{tour_id}/points")
async def add_inspection_point(
    tour_id: int,
    request: InspectionPoint,
    db: Session = Depends(get_db),
    current: Employee = Depends(RequirePermission("inspection.update")),
):
    tour = db.query(InspectionTour).filter(InspectionTour.tour_id == tour_id).first()
    if not tour:
        raise HTTPException(status_code=404, detail="Tour not found")
    if tour.distributor_id != current.employee_id:
        raise HTTPException(status_code=403, detail="Only the assigned distributor can add points")
    if tour.status != "in_progress":
        raise HTTPException(status_code=400, detail="Tour is not in progress")
    point = InspectionTourPoint(
        tour_id=tour_id,
        latitude=request.latitude,
        longitude=request.longitude,
        recorded_at=_parse(request.recorded_at) or datetime.utcnow(),
    )
    db.add(point)
    db.commit()
    return success_response(message="Point added")


@router.post("/{tour_id}/complete")
async def complete_inspection(
    tour_id: int,
    db: Session = Depends(get_db),
    current: Employee = Depends(RequirePermission("inspection.update")),
):
    tour = db.query(InspectionTour).filter(InspectionTour.tour_id == tour_id).first()
    if not tour:
        raise HTTPException(status_code=404, detail="Tour not found")
    if tour.distributor_id != current.employee_id:
        raise HTTPException(status_code=403, detail="Only the assigned distributor can complete this tour")
    if tour.status != "in_progress":
        raise HTTPException(status_code=400, detail="Tour must be in progress to complete")
    tour.status = "completed"
    tour.ended_at = datetime.utcnow()
    db.commit()
    db.refresh(tour)
    return success_response(data=_serialize(tour), message="Inspection tour completed")


@router.post("/{tour_id}/send")
async def send_inspection(
    tour_id: int,
    db: Session = Depends(get_db),
    current: Employee = Depends(RequirePermission("inspection.update")),
):
    tour = db.query(InspectionTour).filter(InspectionTour.tour_id == tour_id).first()
    if not tour:
        raise HTTPException(status_code=404, detail="Tour not found")
    if tour.distributor_id != current.employee_id:
        raise HTTPException(status_code=403, detail="Only the assigned distributor can send this tour")
    if tour.status not in ("completed", "in_progress"):
        raise HTTPException(status_code=400, detail="Tour must be completed before sending")
    tour.status = "sent"
    tour.sent_at = datetime.utcnow()
    db.commit()
    db.refresh(tour)
    return success_response(data=_serialize(tour), message="Inspection tour sent to manager")
