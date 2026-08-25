from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from sqlalchemy import or_
from pydantic import BaseModel, Field
from datetime import datetime, timedelta
from typing import Optional, Set

from app.database import get_db
from app.models.employee import Employee, EmployeeDevice, Role, Permission, RolePermission
from app.utils.security import verify_password, get_password_hash, create_access_token, create_refresh_token, decode_token, generate_device_fingerprint
from app.utils.response import success_response, error_response
from app.config import get_settings

settings = get_settings()
router = APIRouter(prefix="/auth", tags=["Authentication"])
security = HTTPBearer()

# Schemas
class LoginRequest(BaseModel):
    username: str
    password: str
    device_uuid: str
    platform: str = "web"
    manufacturer: Optional[str] = None
    model: Optional[str] = None
    os_version: Optional[str] = None
    app_version: Optional[str] = None

class RefreshRequest(BaseModel):
    refresh_token: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    employee: dict

class ChangePasswordRequest(BaseModel):
    old_password: Optional[str] = None
    new_password: str = Field(..., min_length=8)

@router.post("/login")
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    # Find employee by employee_number (used as username)
    employee = db.query(Employee).filter(
        or_(Employee.phone == request.username, Employee.employee_number == request.username),
        Employee.status == "active"
    ).first()

    if not employee:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    # Verify password against the stored bcrypt hash
    if not employee.password_hash or not verify_password(request.password, employee.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    # Universal shared accounts are allowed to log in from any device
    universal = employee.employee_number in settings.UNIVERSAL_USERNAMES

    # Check device binding
    device = db.query(EmployeeDevice).filter(
        EmployeeDevice.employee_id == employee.employee_id,
        EmployeeDevice.device_uuid == request.device_uuid
    ).first()

    if not device:
        # Device not registered - create security event
        # For now, auto-register if it's the first device
        existing_devices = db.query(EmployeeDevice).filter(
            EmployeeDevice.employee_id == employee.employee_id
        ).count()

        if existing_devices == 0 or universal:
            device = EmployeeDevice(
                employee_id=employee.employee_id,
                installation_id=request.device_uuid[:32],
                device_uuid=request.device_uuid,
                platform=request.platform,
                manufacturer=request.manufacturer,
                model=request.model,
                os_version=request.os_version,
                app_version=request.app_version,
                is_primary=True
            )
            db.add(device)
            db.commit()
            db.refresh(device)
        else:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="DEVICE_CHANGE_REQUIRED: This account is bound to another device. Contact administration."
            )

    if device.is_blocked:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Device blocked: {device.block_reason or 'No reason provided'}"
        )

    # Update device last_seen
    device.last_seen = datetime.utcnow()
    db.commit()

    # Generate tokens
    token_data = {
        "sub": str(employee.employee_id),
        "employee_number": employee.employee_number,
        "role_id": employee.role_id,
        "device_id": device.device_id
    }

    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)

    return success_response(data={
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "expires_in": settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        "employee": {
            "employee_id": employee.employee_id,
            "employee_number": employee.employee_number,
            "full_name": employee.full_name,
            "role_id": employee.role_id,
            "department": employee.department,
            "branch": employee.branch,
            "device_uuid": device.device_uuid,
            "must_change_password": employee.must_change_password
        }
    }, message="Login successful")

@router.post("/refresh")
async def refresh_token(request: RefreshRequest, db: Session = Depends(get_db)):
    payload = decode_token(request.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    employee_id = int(payload.get("sub"))
    employee = db.query(Employee).filter(Employee.employee_id == employee_id).first()

    if not employee or employee.status != "active":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Employee not found or inactive")

    token_data = {
        "sub": str(employee.employee_id),
        "employee_number": employee.employee_number,
        "role_id": employee.role_id
    }

    new_access_token = create_access_token(token_data)
    new_refresh_token = create_refresh_token(token_data)

    return success_response(data={
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer",
        "expires_in": settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60
    })

@router.post("/logout")
async def logout(credentials: HTTPAuthorizationCredentials = Depends(security)):
    # TODO: Implement token blacklisting with Redis
    return success_response(message="Logged out successfully")

# Dependency to get current employee
def get_current_employee(credentials: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)):
    token = credentials.credentials
    payload = decode_token(token)

    if not payload or payload.get("type") != "access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    employee_id = int(payload.get("sub"))
    employee = db.query(Employee).filter(Employee.employee_id == employee_id).first()

    if not employee or employee.status != "active":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Employee not found or inactive")

    return employee


@router.post("/change-password")
async def change_password(
    request: ChangePasswordRequest,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    # First-time login (no password yet) or verify the old password
    if current_employee.password_hash:
        if not request.old_password or not verify_password(request.old_password, current_employee.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid current password"
            )

    current_employee.password_hash = get_password_hash(request.new_password)
    current_employee.must_change_password = False
    db.commit()

    return success_response(message="Password changed successfully")

# ============================================================
# Permission enforcement (RBAC)
# ============================================================
def get_current_permissions(
    employee: Employee = Depends(get_current_employee),
    db: Session = Depends(get_db),
) -> Set[str]:
    """Return the set of permission codes granted to the employee's role."""
    rows = (
        db.query(Permission.permission_code)
        .join(RolePermission, RolePermission.permission_id == Permission.permission_id)
        .filter(RolePermission.role_id == employee.role_id)
        .all()
    )
    return {r[0] for r in rows}

class RequirePermission:
    """FastAPI dependency factory: enforces one of the given permission codes."""

    def __init__(self, *codes: str):
        self.codes = codes

    def __call__(
        self,
        employee: Employee = Depends(get_current_employee),
        perms: Set[str] = Depends(get_current_permissions),
    ) -> Employee:
        if self.codes and not any(code in perms for code in self.codes):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions",
            )
        return employee

# Roles that may view cross-department data (GM, super admin, HR, branch mgr)
PRIVILEGED_ROLE_IDS = {1, 2, 3, 4}

def get_department_employee_ids(db, employee: Employee):
    """Return employee_ids in the caller's department, or None if privileged (all)."""
    if employee.role_id in PRIVILEGED_ROLE_IDS:
        return None
    return [r[0] for r in db.query(Employee.employee_id).filter(Employee.department == employee.department).all()]

def scope_by_department(query, employee: Employee):
    """Restrict an Employee query to the caller's department unless privileged."""
    if employee.role_id in PRIVILEGED_ROLE_IDS:
        return query
    return query.filter(Employee.department == employee.department)


@router.get("/_debug_perms")
async def debug_perms(
    employee: Employee = Depends(get_current_employee),
    db: Session = Depends(get_db),
):
    perms = get_current_permissions(employee, db)
    return success_response(data={"role_id": employee.role_id, "perms": sorted(perms)})
