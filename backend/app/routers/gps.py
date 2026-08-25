from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from app.database import get_db
from app.models.employee import Employee
from app.models.gps import GpsSession, GpsTelemetry
from app.routers.auth import get_current_employee, RequirePermission
from app.routers.websocket import broadcast_employee_location
from app.utils.response import success_response

router = APIRouter(prefix="/gps", tags=["GPS Tracking"])

class TelemetryPoint(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    accuracy: Optional[float] = None
    altitude: Optional[float] = None
    speed: Optional[float] = None
    heading: Optional[float] = None
    battery_level: Optional[int] = Field(None, ge=0, le=100)
    network_type: Optional[str] = None
    recorded_at: datetime

class StartSessionRequest(BaseModel):
    latitude: float
    longitude: float
    device_uuid: str

class TelemetryBatchRequest(BaseModel):
    session_id: UUID
    points: List[TelemetryPoint]

@router.post("/session/start")
async def start_session(
    request: StartSessionRequest,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    session = GpsSession(
        employee_id=current_employee.employee_id,
        started_at=datetime.utcnow(),
        start_location=f"SRID=4326;POINT({request.longitude} {request.latitude})",
        is_active=True
    )
    db.add(session)
    db.commit()
    db.refresh(session)

    return success_response(data={
        "session_id": str(session.session_id),
        "started_at": session.started_at.isoformat()
    }, message="GPS session started")

@router.post("/telemetry")
async def post_telemetry(
    request: TelemetryBatchRequest,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    session = db.query(GpsSession).filter(
        GpsSession.session_id == request.session_id,
        GpsSession.employee_id == current_employee.employee_id,
        GpsSession.is_active == True
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Active GPS session not found")

    for point in request.points:
        telemetry = GpsTelemetry(
            session_id=request.session_id,
            employee_id=current_employee.employee_id,
            coordinates=f"SRID=4326;POINT({point.longitude} {point.latitude})",
            accuracy=point.accuracy,
            altitude=point.altitude,
            speed=point.speed,
            heading=point.heading,
            battery_level=point.battery_level,
            network_type=point.network_type,
            recorded_at=point.recorded_at
        )
        db.add(telemetry)

    session.total_points += len(request.points)
    db.commit()

    last_point = request.points[-1]
    await broadcast_employee_location(
        current_employee.employee_id,
        {
            "latitude": last_point.latitude,
            "longitude": last_point.longitude,
            "speed": last_point.speed,
            "battery_level": last_point.battery_level,
            "last_update": last_point.recorded_at.isoformat(),
        },
    )

    return success_response(data={
        "points_received": len(request.points),
        "session_id": str(request.session_id)
    }, message="Telemetry recorded")

@router.post("/session/end")
async def end_session(
    session_id: UUID,
    latitude: float,
    longitude: float,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    session = db.query(GpsSession).filter(
        GpsSession.session_id == session_id,
        GpsSession.employee_id == current_employee.employee_id,
        GpsSession.is_active == True
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Active GPS session not found")

    session.is_active = False
    session.ended_at = datetime.utcnow()
    session.end_location = f"SRID=4326;POINT({longitude} {latitude})"
    db.commit()

    return success_response(data={
        "session_id": str(session.session_id),
        "ended_at": session.ended_at.isoformat(),
        "total_points": session.total_points
    }, message="GPS session ended")

class TelemetrySyncPoint(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    speed: Optional[float] = None
    accuracy: Optional[float] = None
    recorded_at: datetime


class TelemetrySyncRequest(BaseModel):
    points: List[TelemetrySyncPoint]


@router.post("/telemetry/batch")
async def post_telemetry_batch(
    request: TelemetrySyncRequest,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    """Offline-first bulk ingestion of GPS points (matches mobile GpsTelemetry.toJson).
    Finds or creates an active session for the employee."""
    if not request.points:
        return success_response(data={"points_received": 0})

    session = db.query(GpsSession).filter(
        GpsSession.employee_id == current_employee.employee_id,
        GpsSession.is_active == True
    ).first()

    if not session:
        first = request.points[0]
        session = GpsSession(
            employee_id=current_employee.employee_id,
            started_at=first.recorded_at,
            start_location=f"SRID=4326;POINT({first.longitude} {first.latitude})",
            is_active=True,
        )
        db.add(session)
        db.commit()
        db.refresh(session)

    for p in request.points:
        db.add(GpsTelemetry(
            session_id=session.session_id,
            employee_id=current_employee.employee_id,
            coordinates=f"SRID=4326;POINT({p.longitude} {p.latitude})",
            accuracy=p.accuracy,
            speed=p.speed,
            recorded_at=p.recorded_at,
            is_synced=True,
        ))

    session.total_points += len(request.points)
    db.commit()

    last = request.points[-1]
    await broadcast_employee_location(
        current_employee.employee_id,
        {
            "latitude": last.latitude,
            "longitude": last.longitude,
            "speed": last.speed,
            "last_update": last.recorded_at.isoformat(),
        },
    )

    return success_response(data={
        "points_received": len(request.points),
        "session_id": str(session.session_id),
    }, message="Telemetry batch recorded")


@router.get("/employees/live")
async def get_live_employees(
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("gps.view_live"))
):
    # Get all employees with active GPS sessions
    active_sessions = db.query(GpsSession).filter(
        GpsSession.is_active == True
    ).all()

    result = []
    for session in active_sessions:
        emp = db.query(Employee).filter(Employee.employee_id == session.employee_id).first()
        last_point = db.query(GpsTelemetry).filter(
            GpsTelemetry.session_id == session.session_id
        ).order_by(GpsTelemetry.recorded_at.desc()).first()

        if last_point and emp:
            from geoalchemy2.shape import to_shape
            coords = to_shape(last_point.coordinates)
            result.append({
                "employee_id": emp.employee_id,
                "full_name": emp.full_name,
                "latitude": coords.y,
                "longitude": coords.x,
                "speed": last_point.speed,
                "battery_level": last_point.battery_level,
                "last_update": last_point.recorded_at.isoformat()
            })

    return success_response(data=result)
