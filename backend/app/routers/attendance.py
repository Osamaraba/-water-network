from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy import func
from pydantic import BaseModel, Field
from datetime import datetime, timedelta
from typing import Optional, List
from geoalchemy2.shape import to_shape

from app.database import get_db
from app.models.employee import Employee
from app.models.attendance import AttendanceLog, AttendanceEvent, AttendanceEvidence
from app.models.zone import WorkZone, ZoneAssignment
from app.routers.auth import get_current_employee, RequirePermission, PRIVILEGED_ROLE_IDS
from app.utils.response import success_response, error_response
from app.utils.security import generate_transaction_id, hash_evidence
from app.utils.notifications import create_notification
from app.routers.websocket import broadcast_notification
import os
import uuid

from app.config import get_settings

settings = get_settings()
router = APIRouter(prefix="/attendance", tags=["Attendance"])

# Roles whose attendance is tied to a maintenance schedule + location
MAINTENANCE_ROLE_IDS = {5, 8, 11}

# Field roles eligible for automatic overtime calculation
FIELD_ROLE_IDS = {8, 10, 11, 12, 13, 14}


def compute_overtime_hours(check_in, check_out, shift_start, shift_end, is_night=False):
    if not (check_in and check_out and shift_start and shift_end):
        return 0.0
    sched_start = datetime.combine(check_in.date(), shift_start)
    sched_end = datetime.combine(check_in.date(), shift_end)
    if is_night or shift_end <= shift_start:
        sched_end = sched_end + timedelta(days=1)
    scheduled = (sched_end - sched_start).total_seconds() / 3600
    actual = (check_out - check_in).total_seconds() / 3600
    return round(max(0.0, actual - scheduled), 2)

class CheckInRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    accuracy: float = Field(..., gt=0)
    device_time: datetime
    gps_time: Optional[datetime] = None
    device_uuid: str
    is_mock_location: bool = False
    client_transaction_id: Optional[str] = None

class CheckOutRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    accuracy: float = Field(..., gt=0)
    device_time: datetime
    gps_time: Optional[datetime] = None

class LocateRequest(BaseModel):
    employee_id: int
    message: Optional[str] = None

class TrustScoreResult(BaseModel):
    score: int = Field(..., ge=0, le=100)
    status: str
    reasons: List[str]

def calculate_trust_score(
    accuracy: float,
    is_mock_location: bool,
    device_time: datetime,
    gps_time: Optional[datetime],
    server_time: datetime,
    employee_id: int,
    db: Session
) -> TrustScoreResult:
    score = 100
    reasons = []

    # GPS Accuracy check
    if accuracy > settings.GPS_ACCURACY_THRESHOLD:
        score -= 30
        reasons.append("GPS_ACCURACY_LOW")

    # Mock location check
    if is_mock_location:
        score -= 50
        reasons.append("MOCK_LOCATION_SUSPECTED")

    # Time checks
    if gps_time:
        time_diff = abs((device_time - gps_time).total_seconds())
        if time_diff > 60:
            score -= 20
            reasons.append("CLOCK_DISCREPANCY")

    server_diff = abs((device_time - server_time).total_seconds())
    if server_diff > 300:  # 5 minutes
        score -= 15
        reasons.append("DEVICE_TIME_OFFSET")

    # Determine status
    if score >= 80:
        status = "valid"
    elif score >= 60:
        status = "review"
    elif score >= 40:
        status = "suspicious"
    else:
        status = "rejected"

    return TrustScoreResult(score=score, status=status, reasons=reasons)

def check_geofence(lat: float, lng: float, employee_id: int, db: Session):
    """Return (inside, zones_exist) for the employee's assigned work zones.
    Enforces a defined radius/polygon per team."""
    from geoalchemy2 import func as geo_func
    from geoalchemy2.shape import from_shape
    from shapely.geometry import Point

    zones = (
        db.query(WorkZone)
        .join(WorkZone.assignments)
        .filter(
            WorkZone.is_active == True,
            ZoneAssignment.employee_id == employee_id,
        )
        .all()
    )

    if not zones:
        return (False, False)  # No assigned zones = no geofence constraint

    for zone in zones:
        if zone.zone_type == "radius_point" and zone.center_point and zone.radius_meters:
            center = to_shape(zone.center_point)
            from math import radians, cos, sin, asin, sqrt
            lon1, lat1, lon2, lat2 = map(radians, [center.x, center.y, lng, lat])
            dlon = lon2 - lon1
            dlat = lat2 - lat1
            a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
            c = 2 * asin(sqrt(a))
            distance = 6371000 * c  # Earth radius in meters
            if distance <= zone.radius_meters:
                return (True, True)
        elif zone.zone_type == "polygon" and zone.boundary_polygon:
            pt = from_shape(Point(lng, lat), srid=4326)
            contained = db.query(geo_func.ST_Contains(zone.boundary_polygon, pt)).scalar()
            if contained:
                return (True, True)

    return (False, True)

@router.post("/check-in")
async def check_in(
    request: CheckInRequest,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    server_time = datetime.utcnow()

    # Calculate trust score
    trust = calculate_trust_score(
        accuracy=request.accuracy,
        is_mock_location=request.is_mock_location,
        device_time=request.device_time,
        gps_time=request.gps_time,
        server_time=server_time,
        employee_id=current_employee.employee_id,
        db=db
    )

    # Check geofence (enforced only when assigned work zones exist)
    inside, zones_exist = check_geofence(request.latitude, request.longitude, current_employee.employee_id, db)
    if zones_exist and not inside:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="OUTSIDE_GEOFENCE: must be within the assigned work radius",
        )
    if not inside:
        trust.reasons.append("OUTSIDE_GEOFENCE")

    # Maintenance teams: attendance tied to their schedule (shift window) + location
    if current_employee.role_id in MAINTENANCE_ROLE_IDS and current_employee.shift_start and current_employee.shift_end:
        t = request.device_time.time()
        if not (current_employee.shift_start <= t <= current_employee.shift_end):
            trust.score -= 15
            trust.reasons.append("OUTSIDE_SHIFT_WINDOW")
            if trust.score < 40:
                trust.status = "rejected"

    # Check for existing active session
    active_log = db.query(AttendanceLog).filter(
        AttendanceLog.employee_id == current_employee.employee_id,
        AttendanceLog.check_out_time.is_(None)
    ).first()

    if active_log:
        raise HTTPException(status_code=400, detail="Active attendance session already exists")

    # Create attendance log
    transaction_id = request.client_transaction_id or generate_transaction_id()

    attendance_log = AttendanceLog(
        employee_id=current_employee.employee_id,
        check_in_time=request.device_time,
        check_in_location=f"SRID=4326;POINT({request.longitude} {request.latitude})",
        check_in_accuracy=request.accuracy,
        client_transaction_id=transaction_id,
        trust_score=trust.score,
        trust_status=trust.status,
        trust_reasons={"reasons": trust.reasons},
        server_check_in_time=server_time,
        device_time_offset_seconds=int((request.device_time - server_time).total_seconds()),
        is_mock_location_detected=request.is_mock_location
    )

    db.add(attendance_log)
    db.commit()
    db.refresh(attendance_log)

    # Auto-notify the overseeing supervisor and HR on every check-in
    if current_employee.supervisor_id:
        create_notification(
            db,
            current_employee.supervisor_id,
            "attendance.checkin",
            "تسجيل دوام",
            f"سجّل {current_employee.full_name} دوامه",
            data={"employee_id": current_employee.employee_id, "log_id": attendance_log.log_id},
        )
    for hr in db.query(Employee).filter(Employee.role_id == 3, Employee.status == "active").all():
        create_notification(
            db,
            hr.employee_id,
            "attendance.checkin",
            "تسجيل دوام",
            f"سجّل {current_employee.full_name} الدوام",
            data={"employee_id": current_employee.employee_id, "log_id": attendance_log.log_id},
        )

    return success_response(data={
        "log_id": attendance_log.log_id,
        "session_id": str(attendance_log.session_id),
        "transaction_id": transaction_id,
        "check_in_time": attendance_log.check_in_time.isoformat(),
        "trust_score": trust.score,
        "trust_status": trust.status,
        "in_geofence": inside,
        "server_time": server_time.isoformat()
    }, message="Check-in successful")

@router.post("/check-out")
async def check_out(
    request: CheckOutRequest,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    server_time = datetime.utcnow()

    # Find active session
    active_log = db.query(AttendanceLog).filter(
        AttendanceLog.employee_id == current_employee.employee_id,
        AttendanceLog.check_out_time.is_(None)
    ).first()

    if not active_log:
        raise HTTPException(status_code=400, detail="No active attendance session found")

    # Update log
    active_log.check_out_time = request.device_time
    active_log.check_out_location = f"SRID=4326;POINT({request.longitude} {request.latitude})"
    active_log.check_out_accuracy = request.accuracy
    active_log.server_check_out_time = server_time

    db.commit()
    db.refresh(active_log)

    # Calculate work duration
    duration = (active_log.check_out_time - active_log.check_in_time).total_seconds() / 3600

    # Overtime for field employees (actual - scheduled shift)
    if current_employee.role_id in FIELD_ROLE_IDS:
        active_log.overtime_hours = compute_overtime_hours(
            active_log.check_in_time, active_log.check_out_time,
            current_employee.shift_start, current_employee.shift_end,
        )
        db.commit()

    return success_response(data={
        "log_id": active_log.log_id,
        "session_id": str(active_log.session_id),
        "check_out_time": active_log.check_out_time.isoformat(),
        "work_duration_hours": round(duration, 2),
        "overtime_hours": active_log.overtime_hours or 0,
        "trust_score": active_log.trust_score,
        "trust_status": active_log.trust_status
    }, message="Check-out successful")

@router.get("/")
async def get_attendance(
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    query = db.query(AttendanceLog).filter(
        AttendanceLog.employee_id == current_employee.employee_id
    )

    if date_from:
        query = query.filter(AttendanceLog.check_in_time >= date_from)
    if date_to:
        query = query.filter(AttendanceLog.check_in_time <= date_to)

    logs = query.order_by(AttendanceLog.check_in_time.desc()).all()

    return success_response(data=[{
        "log_id": log.log_id,
        "check_in_time": log.check_in_time.isoformat() if log.check_in_time else None,
        "check_out_time": log.check_out_time.isoformat() if log.check_out_time else None,
        "trust_score": log.trust_score,
        "trust_status": log.trust_status,
        "is_offline_sync": log.is_offline_sync,
        "overtime_hours": log.overtime_hours or 0,
    } for log in logs])


@router.get("/all")
async def get_all_attendance(
    employee_id: Optional[int] = None,
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("attendance.view")),
):
    """Privileged: attendance logs across employees (for daily/monthly reports)."""
    query = db.query(
        AttendanceLog.log_id,
        AttendanceLog.employee_id,
        AttendanceLog.check_in_time,
        AttendanceLog.check_out_time,
        AttendanceLog.trust_status,
        AttendanceLog.overtime_hours,
        Employee.employee_number,
        Employee.full_name,
        Employee.department,
        Employee.role_id,
    ).join(Employee, Employee.employee_id == AttendanceLog.employee_id)

    if employee_id is not None:
        query = query.filter(AttendanceLog.employee_id == employee_id)
    if date_from:
        query = query.filter(AttendanceLog.check_in_time >= date_from)
    if date_to:
        query = query.filter(AttendanceLog.check_in_time <= date_to)

    rows = query.order_by(AttendanceLog.check_in_time.desc()).all()

    return success_response(data=[{
        "log_id": r.log_id,
        "employee_id": r.employee_id,
        "employee_number": r.employee_number,
        "full_name": r.full_name,
        "department": r.department,
        "role_id": r.role_id,
        "check_in_time": r.check_in_time.isoformat() if r.check_in_time else None,
        "check_out_time": r.check_out_time.isoformat() if r.check_out_time else None,
        "trust_status": r.trust_status,
        "overtime_hours": r.overtime_hours or 0,
    } for r in rows])

@router.get("/overtime")
async def overtime_summary(
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("overtime.view"))
):
    """Aggregated overtime hours for field employees within a date range.
    Privileged roles see everyone; others see their department only."""
    query = db.query(
        AttendanceLog.employee_id,
        func.sum(AttendanceLog.overtime_hours).label("total_overtime"),
        func.count(AttendanceLog.log_id).label("days"),
    ).filter(AttendanceLog.overtime_hours > 0)

    if date_from:
        query = query.filter(AttendanceLog.check_in_time >= date_from)
    if date_to:
        query = query.filter(AttendanceLog.check_in_time <= date_to)

    if current_employee.role_id not in PRIVILEGED_ROLE_IDS:
        emp_ids = [e.employee_id for e in db.query(Employee).filter(
            Employee.department == current_employee.department,
            Employee.status == "active"
        ).all()]
        query = query.filter(AttendanceLog.employee_id.in_(emp_ids))

    query = query.group_by(AttendanceLog.employee_id).order_by(func.sum(AttendanceLog.overtime_hours).desc())
    rows = query.all()

    result = []
    for emp_id, total, days in rows:
        emp = db.query(Employee).filter(Employee.employee_id == emp_id).first()
        result.append({
            "employee_id": emp_id,
            "full_name": emp.full_name if emp else None,
            "department": emp.department if emp else None,
            "total_overtime_hours": round(float(total or 0), 2),
            "days": days,
        })

    return success_response(data=result)


@router.post("/locate")
async def locate_employee(
    request: LocateRequest,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("attendance.view"))
):
    """Supervisor requests a field employee to broadcast their current location."""
    target = db.query(Employee).filter(Employee.employee_id == request.employee_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="Employee not found")

    create_notification(
        db,
        target.employee_id,
        "locate",
        "طلب تحديد الموقع",
        request.message or "يرجى تحديث موقعك الحالي",
        severity="warning",
        data={"by_employee_id": current_employee.employee_id},
    )
    await broadcast_notification({
        "employee_id": target.employee_id,
        "by": current_employee.employee_id,
        "message": request.message,
    })

    return success_response(message="Locate alert sent")

@router.get("/tree")
async def attendance_tree(
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(RequirePermission("attendance.view"))
):
    """Attendance monitoring tree following the permission hierarchy.
    GM/HR/Branch see the full tree from the top; a director/supervisor sees
    their own subtree (their team)."""
    if current_employee.role_id in PRIVILEGED_ROLE_IDS:
        roots = db.query(Employee).filter(
            Employee.supervisor_id.is_(None),
            Employee.status == "active"
        ).all()
    else:
        roots = [current_employee]

    def build_node(emp: Employee) -> dict:
        children = db.query(Employee).filter(
            Employee.supervisor_id == emp.employee_id,
            Employee.status == "active"
        ).all()
        log = db.query(AttendanceLog).filter(
            AttendanceLog.employee_id == emp.employee_id,
            AttendanceLog.check_in_time >= func.current_date
        ).first()
        return {
            "employee_id": emp.employee_id,
            "employee_number": emp.employee_number,
            "full_name": emp.full_name,
            "department": emp.department,
            "role_id": emp.role_id,
            "attendance_today": {
                "checked_in": log is not None,
                "check_in_time": log.check_in_time.isoformat() if log and log.check_in_time else None,
                "trust_status": log.trust_status if log else None,
            },
            "children": [build_node(c) for c in children],
        }

    return success_response(data=[build_node(r) for r in roots])


# ============================================================
# Offline-first sync: ingest locally-stored attendance logs
# (matches the mobile app's AttendanceLog.toJson() contract)
# ============================================================
class AttendanceSyncItem(BaseModel):
    employee_id: Optional[int] = None  # ignored; JWT is authoritative
    check_in_time: datetime
    check_out_time: Optional[datetime] = None
    check_in_lat: float = Field(..., ge=-90, le=90)
    check_in_lng: float = Field(..., ge=-180, le=180)
    check_out_lat: Optional[float] = None
    check_out_lng: Optional[float] = None
    check_in_image_path: Optional[str] = None
    check_out_image_path: Optional[str] = None
    check_in_image_url: Optional[str] = None
    check_out_image_url: Optional[str] = None
    is_offline_sync: bool = True
    overtime_approved_hours: float = 0.0
    is_mock_location_detected: Optional[bool] = False
    gps_accuracy_meters: Optional[float] = None
    image_hash: Optional[str] = None
    transaction_id: Optional[str] = None


class AttendanceSyncRequest(BaseModel):
    records: List[AttendanceSyncItem]


class AttendanceSyncResult(BaseModel):
    transaction_id: str
    status: str
    log_id: Optional[int] = None
    detail: Optional[str] = None


def _notify_checkin(db: Session, employee: Employee, log_id: int):
    if employee.supervisor_id:
        create_notification(
            db, employee.supervisor_id, "attendance.checkin", "تسجيل دوام",
            f"سجّل {employee.full_name} دوامه (مزامنة)",
            data={"employee_id": employee.employee_id, "log_id": log_id},
        )
    for hr in db.query(Employee).filter(Employee.role_id == 3, Employee.status == "active").all():
        create_notification(
            db, hr.employee_id, "attendance.checkin", "تسجيل دوام",
            f"سجّل {employee.full_name} الدوام (مزامنة)",
            data={"employee_id": employee.employee_id, "log_id": log_id},
        )


@router.post("/sync")
async def sync_attendance(
    request: AttendanceSyncRequest,
    db: Session = Depends(get_db),
    current_employee: Employee = Depends(get_current_employee)
):
    """Bulk, idempotent ingestion of offline attendance logs from the mobile app.
    Each record is keyed by client_transaction_id (idempotency)."""
    server_time = datetime.utcnow()
    results: List[dict] = []

    for item in request.records:
        txn = item.transaction_id or generate_transaction_id()

        existing = db.query(AttendanceLog).filter(
            AttendanceLog.client_transaction_id == txn,
            AttendanceLog.employee_id == current_employee.employee_id,
        ).first()

        if existing:
            if item.check_out_time and not existing.check_out_time:
                existing.check_out_time = item.check_out_time
                if item.check_out_lat is not None and item.check_out_lng is not None:
                    existing.check_out_location = f"SRID=4326;POINT({item.check_out_lng} {item.check_out_lat})"
                existing.is_offline_sync = True
                db.commit()
            results.append({"transaction_id": txn, "status": "already_synced", "log_id": existing.log_id})
            continue

        accuracy = item.gps_accuracy_meters or 0.0
        trust = calculate_trust_score(
            accuracy=accuracy,
            is_mock_location=bool(item.is_mock_location_detected),
            device_time=item.check_in_time,
            gps_time=None,
            server_time=server_time,
            employee_id=current_employee.employee_id,
            db=db,
        )

        inside, zones_exist = check_geofence(item.check_in_lat, item.check_in_lng, current_employee.employee_id, db)
        if zones_exist and not inside:
            results.append({"transaction_id": txn, "status": "error", "detail": "OUTSIDE_GEOFENCE"})
            continue
        if not inside:
            trust.reasons.append("OUTSIDE_GEOFENCE")

        if current_employee.role_id in MAINTENANCE_ROLE_IDS and current_employee.shift_start and current_employee.shift_end:
            t = item.check_in_time.time()
            if not (current_employee.shift_start <= t <= current_employee.shift_end):
                trust.score -= 15
                trust.reasons.append("OUTSIDE_SHIFT_WINDOW")
                if trust.score < 40:
                    trust.status = "rejected"

        checkout_loc = None
        if item.check_out_lat is not None and item.check_out_lng is not None:
            checkout_loc = f"SRID=4326;POINT({item.check_out_lng} {item.check_out_lat})"

        log = AttendanceLog(
            employee_id=current_employee.employee_id,
            check_in_time=item.check_in_time,
            check_in_location=f"SRID=4326;POINT({item.check_in_lng} {item.check_in_lat})",
            check_in_accuracy=accuracy,
            check_out_time=item.check_out_time,
            check_out_location=checkout_loc,
            check_in_image_url=item.check_in_image_url,
            check_out_image_url=item.check_out_image_url,
            is_offline_sync=True,
            client_transaction_id=txn,
            trust_score=trust.score,
            trust_status=trust.status,
            trust_reasons={"reasons": trust.reasons},
            server_check_in_time=server_time,
            server_check_out_time=server_time if item.check_out_time else None,
            device_time_offset_seconds=int(_safe_offset(item.check_in_time, server_time)),
            is_mock_location_detected=bool(item.is_mock_location_detected),
        )
        db.add(log)
        db.commit()
        db.refresh(log)

        if log.check_out_time and current_employee.role_id in FIELD_ROLE_IDS:
            log.overtime_hours = compute_overtime_hours(
                log.check_in_time, log.check_out_time,
                current_employee.shift_start, current_employee.shift_end,
            )
            db.commit()

        _notify_checkin(db, current_employee, log.log_id)

        results.append({"transaction_id": txn, "status": "created", "log_id": log.log_id})

    created = sum(1 for r in results if r["status"] == "created")
    return success_response(data={
        "total": len(results),
        "created": created,
        "already_synced": sum(1 for r in results if r["status"] == "already_synced"),
        "errors": sum(1 for r in results if r["status"] == "error"),
        "results": results,
    }, message="Attendance sync completed")


def _safe_offset(device_time: datetime, server_time: datetime) -> float:
    try:
        return (device_time - server_time).total_seconds()
    except Exception:
        return 0.0


# ============================================================
# Evidence image upload (served locally; production: object storage)
# ============================================================
UPLOAD_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "uploads", "evidence"
)


@router.post("/evidence")
async def upload_evidence(
    file: UploadFile = File(...),
    current_employee: Employee = Depends(get_current_employee)
):
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    ext = os.path.splitext(file.filename or "img.jpg")[1].lower()
    if ext not in (".jpg", ".jpeg", ".png", ".webp"):
        raise HTTPException(status_code=400, detail="Unsupported image type")
    fname = f"{current_employee.employee_id}_{uuid.uuid4().hex}{ext}"
    path = os.path.join(UPLOAD_DIR, fname)
    content = await file.read()
    with open(path, "wb") as f:
        f.write(content)
    return success_response(data={
        "url": f"/uploads/evidence/{fname}",
        "hash": hash_evidence(content),
    }, message="Evidence uploaded")

