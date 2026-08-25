from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List

from app.database import get_db
from app.models.employee import Employee
from app.models.incident import Incident, IncidentStatusHistory, IncidentPhoto
from app.routers.auth import get_current_employee, RequirePermission, get_department_employee_ids
from app.utils.notifications import notify_department_field_workers
from app.utils.response import success_response

router = APIRouter(prefix="/incidents", tags=["Incidents"])

class IncidentCreateRequest(BaseModel):
    incident_type: str
    priority: str = Field("medium", pattern="^(low|medium|high|critical)$")
    title: str
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    location_address: Optional[str] = None

class IncidentStatusUpdate(BaseModel):
    status: str = Field(..., pattern="^(accepted|en_route|arrived|in_progress|waiting|completed|cancelled)$")
    notes: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

@router.post("/")
async def create_incident(
    request: IncidentCreateRequest,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    import uuid
    incident = Incident(
        incident_number=f"INC-{datetime.utcnow().strftime('%Y%m%d')}-{str(uuid.uuid4())[:8].upper()}",
        incident_type=request.incident_type,
        priority=request.priority,
        title=request.title,
        description=request.description,
        location=f"SRID=4326;POINT({request.longitude} {request.latitude})" if request.latitude and request.longitude else None,
        location_address=request.location_address,
        created_by=current_employee.employee_id
    )
    db.add(incident)
    db.commit()
    db.refresh(incident)

    # Notify active (checked-in) field workers of the creator's department.
    # Employees who have checked out are excluded automatically by the helper.
    creator = db.query(Employee).filter(Employee.employee_id == current_employee.employee_id).first()
    if creator and creator.department:
        notify_department_field_workers(
            db,
            creator.department,
            "incident.new",
            "بلاغ جديد",
            f"بلاغ: {incident.title}",
            data={"incident_id": incident.incident_id},
        )

    return success_response(data={
        "incident_id": incident.incident_id,
        "incident_number": incident.incident_number,
        "status": incident.status
    }, message="Incident created")

@router.post("/{incident_id}/accept")
async def accept_incident(
    incident_id: int,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    incident = db.query(Incident).filter(Incident.incident_id == incident_id).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")

    if incident.status != "new" and incident.status != "assigned":
        raise HTTPException(status_code=400, detail=f"Cannot accept incident in status: {incident.status}")

    incident.status = "accepted"
    incident.assigned_employee_id = current_employee.employee_id
    incident.accepted_at = datetime.utcnow()
    db.commit()

    return success_response(data={"incident_id": incident_id, "status": "accepted"})

@router.post("/{incident_id}/arrive")
async def arrive_incident(
    incident_id: int,
    latitude: float,
    longitude: float,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    incident = db.query(Incident).filter(Incident.incident_id == incident_id).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")

    if incident.status != "accepted" and incident.status != "en_route":
        raise HTTPException(status_code=400, detail="Cannot arrive - incident not accepted")

    incident.status = "arrived"
    incident.arrived_at = datetime.utcnow()
    db.commit()

    return success_response(data={"incident_id": incident_id, "status": "arrived"})

@router.post("/{incident_id}/start")
async def start_incident(
    incident_id: int,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    incident = db.query(Incident).filter(Incident.incident_id == incident_id).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")

    if incident.status != "arrived":
        raise HTTPException(status_code=400, detail="Cannot start - must arrive first")

    incident.status = "in_progress"
    incident.started_at = datetime.utcnow()
    db.commit()

    return success_response(data={"incident_id": incident_id, "status": "in_progress"})

@router.post("/{incident_id}/complete")
async def complete_incident(
    incident_id: int,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    incident = db.query(Incident).filter(Incident.incident_id == incident_id).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")

    if incident.status != "in_progress":
        raise HTTPException(status_code=400, detail="Cannot complete - repair not started")

    incident.status = "completed"
    incident.completed_at = datetime.utcnow()
    db.commit()

    return success_response(data={"incident_id": incident_id, "status": "completed"})

@router.get("/")
async def list_incidents(
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    query = db.query(Incident)
    dept_ids = get_department_employee_ids(db, current_employee)
    if dept_ids is not None:
        query = query.filter(Incident.created_by.in_(dept_ids))
    if status:
        query = query.filter(Incident.status == status)

    incidents = query.order_by(Incident.created_at.desc()).all()
    return success_response(data=[{
        "incident_id": i.incident_id,
        "incident_number": i.incident_number,
        "title": i.title,
        "status": i.status,
        "priority": i.priority,
        "created_at": i.created_at.isoformat() if i.created_at else None
    } for i in incidents])
