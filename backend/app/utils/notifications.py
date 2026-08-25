from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional, Dict, Any


def has_active_attendance_session(db: Session, employee_id: int) -> bool:
    """True if the employee is currently checked-in (no check-out yet).
    Used to gate maintenance notifications: a checked-out employee must not
    receive new incident alerts."""
    from app.models.attendance import AttendanceLog

    log = (
        db.query(AttendanceLog)
        .filter(
            AttendanceLog.employee_id == employee_id,
            AttendanceLog.check_out_time.is_(None),
        )
        .first()
    )
    return log is not None


def create_notification(
    db: Session,
    employee_id: Optional[int],
    notification_type: str,
    title: str,
    message: str,
    severity: str = "info",
    data: Optional[Dict[str, Any]] = None,
) -> "object":
    from app.models.notification import Notification

    notification = Notification(
        employee_id=employee_id,
        notification_type=notification_type,
        title=title,
        message=message,
        severity=severity,
        data=data,
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)
    return notification


def notify_department_field_workers(
    db: Session,
    department: str,
    notification_type: str,
    title: str,
    message: str,
    data: Optional[Dict[str, Any]] = None,
    field_role_ids: tuple = (11, 12, 13),
):
    """Notify active (checked-in) field workers of a department.
    Checked-out workers are excluded automatically via has_active_attendance_session."""
    from app.models.employee import Employee

    workers = (
        db.query(Employee)
        .filter(
            Employee.role_id.in_(field_role_ids),
            Employee.department == department,
            Employee.status == "active",
        )
        .all()
    )
    for w in workers:
        if has_active_attendance_session(db, w.employee_id):
            create_notification(
                db,
                w.employee_id,
                notification_type,
                title,
                message,
                severity="warning",
                data=data,
            )
