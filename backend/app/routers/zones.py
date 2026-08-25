from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List

from app.database import get_db
from app.models.employee import Employee
from app.models.zone import WorkZone, ZoneAssignment
from app.routers.auth import get_current_employee
from app.utils.response import success_response

router = APIRouter(prefix="/zones", tags=["Work Zones"])

class ZoneCreateRequest(BaseModel):
    zone_name: str
    zone_type: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    radius_meters: Optional[float] = None
    polygon_points: Optional[List[List[float]]] = None
    description: Optional[str] = None

@router.get("")
async def list_zones(
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    zones = db.query(WorkZone).filter(WorkZone.is_active == True).all()
    return success_response(data=[{
        "zone_id": z.zone_id,
        "zone_name": z.zone_name,
        "zone_type": z.zone_type,
        "description": z.description,
        "is_active": z.is_active
    } for z in zones])

@router.get("/employee/{employee_id}")
async def get_employee_zones(
    employee_id: int,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    assignments = db.query(ZoneAssignment).filter(
        ZoneAssignment.employee_id == employee_id
    ).all()

    zones = []
    for assignment in assignments:
        zone = db.query(WorkZone).filter(WorkZone.zone_id == assignment.zone_id).first()
        if zone:
            zones.append({
                "zone_id": zone.zone_id,
                "zone_name": zone.zone_name,
                "zone_type": zone.zone_type,
                "assigned_from": assignment.assigned_from.isoformat() if assignment.assigned_from else None
            })

    return success_response(data=zones)
