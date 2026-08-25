from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List

from app.database import get_db
from app.models.employee import Employee, EmployeeDevice
from app.routers.auth import get_current_employee, RequirePermission, scope_by_department
from app.utils.response import success_response

router = APIRouter(prefix="/employees", tags=["Employees"])

class EmployeeResponse(BaseModel):
    employee_id: int
    employee_number: str
    full_name: str
    phone: Optional[str]
    email: Optional[str]
    department: Optional[str]
    branch: Optional[str]
    role_id: int
    status: str

    class Config:
        from_attributes = True

class ProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None

    class Config:
        extra = "forbid"


@router.patch("/me")
async def update_my_profile(
    payload: ProfileUpdate,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee),
):
    if payload.full_name is not None:
        current_employee.full_name = payload.full_name.strip()
    if payload.phone is not None:
        current_employee.phone = payload.phone.strip()

    db.commit()
    db.refresh(current_employee)

    return success_response(data={
        "employee_id": current_employee.employee_id,
        "employee_number": current_employee.employee_number,
        "full_name": current_employee.full_name,
        "phone": current_employee.phone,
        "email": current_employee.email,
        "department": current_employee.department,
        "branch": current_employee.branch,
        "role_id": current_employee.role_id,
        "status": current_employee.status,
    }, message="تم تحديث الملف الشخصي")


@router.get("", response_model=List[EmployeeResponse])
async def list_employees(
    department: Optional[str] = None,
    branch: Optional[str] = None,
    status: Optional[str] = "active",
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("employee.view"))
):
    query = scope_by_department(db.query(Employee), current_employee)

    if department:
        query = query.filter(Employee.department == department)
    if branch:
        query = query.filter(Employee.branch == branch)
    if status:
        query = query.filter(Employee.status == status)

    employees = query.all()
    return employees

@router.get("/{employee_id}")
async def get_employee(
    employee_id: int,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("employee.view"))
):
    employee = db.query(Employee).filter(Employee.employee_id == employee_id).first()
    if not employee:
        raise HTTPException(status_code=404, detail="Employee not found")

    devices = db.query(EmployeeDevice).filter(
        EmployeeDevice.employee_id == employee_id
    ).all()

    return success_response(data={
        "employee_id": employee.employee_id,
        "employee_number": employee.employee_number,
        "full_name": employee.full_name,
        "phone": employee.phone,
        "email": employee.email,
        "department": employee.department,
        "branch": employee.branch,
        "role_id": employee.role_id,
        "status": employee.status,
        "devices": [{
            "device_id": d.device_id,
            "platform": d.platform,
            "model": d.model,
            "is_primary": d.is_primary,
            "is_blocked": d.is_blocked,
            "last_seen": d.last_seen.isoformat() if d.last_seen else None
        } for d in devices]
    })
