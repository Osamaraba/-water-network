from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
import uuid
import os
import time

from app.config import get_settings
from app.database import engine, Base, SessionLocal
from app.routers import auth, employees, attendance, gps, zones, incidents, websocket, shifts, departures, reports, evaluations, incentives, inspections

settings = get_settings()

# PostGIS availability is detected at import time in app.geo (which enables the
# extension when supported). Geometry columns then use native types; otherwise
# they fall back to TEXT so the rest of the platform still runs.
# Create tables (set DB_RESET=1 to drop & recreate the schema from scratch)
if os.getenv("DB_RESET") == "1":
    from sqlalchemy import text
    engine.dispose()
    with engine.connect() as conn:
        conn.execution_options(isolation_level="AUTOCOMMIT")
        conn.execute(text("DROP SCHEMA public CASCADE"))
        conn.execute(text("CREATE SCHEMA public"))
        conn.execute(text("GRANT ALL ON SCHEMA public TO public"))
    engine.dispose()

# Ensure the PostGIS extension exists (required for geometry columns).
# It may have been removed by DROP SCHEMA above, or be missing on a fresh DB.
from sqlalchemy import text
try:
    with engine.connect() as conn:
        conn.execution_options(isolation_level="AUTOCOMMIT")
        conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
except Exception as _e:
    print("WARN: could not create postgis extension:", _e)

Base.metadata.create_all(bind=engine)


def _seed_feature_permissions():
    """Idempotently insert performance/inspection permission codes and grant them to roles."""
    from app.models.employee import Permission, RolePermission

    perms = [
        ("evaluation.create", "Create performance evaluation", "performance"),
        ("evaluation.view", "View performance evaluations", "performance"),
        ("incentive.view", "View incentives", "performance"),
        ("incentive.manage", "Manage/approve incentives", "performance"),
        ("inspection.create", "Assign inspection tours", "inspection"),
        ("inspection.view", "View inspection tours", "inspection"),
        ("inspection.update", "Update inspection tour (distributor)", "inspection"),
        ("departure.create", "Request a departure (official/personal)", "attendance"),
        ("departure.view_own", "View own departures", "attendance"),
        ("departure.hr_review", "Review/approve employee departures (HR)", "attendance"),
    ]
    with SessionLocal() as db:
        for code, name, module in perms:
            if not db.query(Permission).filter(Permission.permission_code == code).first():
                db.add(Permission(permission_code=code, permission_name=name, module=module))
        db.commit()

        grants = {
            "evaluation.create": [1, 2, 3, 4, 5, 6, 7, 8],
            "evaluation.view": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
            "incentive.view": [1, 2, 3, 4, 5, 6, 7, 8, 16, 17],
            "incentive.manage": [1, 2, 3],
            "inspection.create": [1, 2, 4, 5, 6, 8],
            "inspection.view": [1, 2, 3, 4, 5, 6, 7, 8, 12],
            "inspection.update": [12],
            "departure.create": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
            "departure.view_own": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
            "departure.hr_review": [1, 2, 3],
        }
        for code, role_ids in grants.items():
            perm = db.query(Permission).filter(Permission.permission_code == code).first()
            if not perm:
                continue
            for rid in role_ids:
                exists = db.query(RolePermission).filter_by(
                    role_id=rid, permission_id=perm.permission_id
                ).first()
                if not exists:
                    db.add(RolePermission(role_id=rid, permission_id=perm.permission_id))
        db.commit()


def _seed_roles():
    """Idempotently create the 17 platform roles."""
    from app.models.employee import Role

    roles = [
        (1, "super_admin", "مشرف النظام"),
        (2, "general_manager", "المدير العام"),
        (3, "hr_manager", "مدير الموارد البشرية"),
        (4, "branch_manager", "مدير الفرع"),
        (5, "maintenance_director", "مدير الصيانة"),
        (6, "distribution_director", "مدير التوزيع"),
        (7, "sewage_director", "مدير الصرف الصحي"),
        (8, "field_supervisor", "مشرف ميداني"),
        (9, "office_employee", "موظف مكتبي"),
        (10, "office_field_employee", "موظف مكتبي ميداني"),
        (11, "maintenance_tech", "فني صيانة"),
        (12, "water_distributor", "موزع مياه"),
        (13, "sewage_worker", "عامل صرف صحي"),
        (14, "collector", "محصل"),
        (15, "gis_engineer", "مهندس نظم المعلومات الجغرافية"),
        (16, "auditor", "مدقق"),
        (17, "read_only", "مستخدم للقراءة فقط"),
    ]
    with SessionLocal() as db:
        for role_id, name, label in roles:
            if not db.query(Role).filter(Role.role_id == role_id).first():
                db.add(Role(role_id=role_id, role_name=name, role_label=label, is_active=True))
        db.commit()


def _seed_superuser():
    """Idempotently create a default super_admin account for first login."""
    from app.models.employee import Employee
    from app.utils.security import get_password_hash

    with SessionLocal() as db:
        if db.query(Employee).filter(Employee.employee_number == "admin").first():
            return
        admin = Employee(
            employee_number="admin",
            full_name="مشرف النظام",
            phone="0000000000",
            email="admin@yarmouk-water.jo",
            department="الإدارة",
            branch="المركز الرئيسي",
            role_id=1,
            status="active",
            must_change_password=False,
            password_hash=get_password_hash("Yarmouk@2025"),
        )
        db.add(admin)
        db.commit()


def _seed_universal_user():
    """Idempotently create the shared universal account (everyone logs in with it)."""
    from app.models.employee import Employee
    from app.utils.security import get_password_hash

    with SessionLocal() as db:
        if db.query(Employee).filter(Employee.employee_number == "ENG.OR").first():
            return
        universal = Employee(
            employee_number="ENG.OR",
            full_name="ENG.OR",
            phone="0000000000",
            email="eng.or@yarmouk-water.jo",
            department="الإدارة",
            branch="المركز الرئيسي",
            role_id=1,
            status="active",
            must_change_password=False,
            password_hash=get_password_hash("ENG.OR"),
        )
        db.add(universal)
        db.commit()


_seed_feature_permissions()
_seed_roles()
_seed_superuser()
_seed_universal_user()

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Yarmouk Water Company - Employee Attendance & Field Operations Platform",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly in production
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request ID middleware
@app.middleware("http")
async def add_request_id(request: Request, call_next):
    request_id = str(uuid.uuid4())
    request.state.request_id = request_id
    start_time = time.time()

    response = await call_next(request)

    process_time = time.time() - start_time
    response.headers["X-Request-ID"] = request_id
    response.headers["X-Process-Time"] = str(process_time)

    return response

# Include routers
app.include_router(auth.router, prefix="/v1")
app.include_router(employees.router, prefix="/v1")
app.include_router(attendance.router, prefix="/v1")
app.include_router(gps.router, prefix="/v1")
app.include_router(zones.router, prefix="/v1")
app.include_router(incidents.router, prefix="/v1")
app.include_router(websocket.router, prefix="/v1")
app.include_router(shifts.router, prefix="/v1")
app.include_router(reports.router, prefix="/v1")
app.include_router(evaluations.router, prefix="/v1")
app.include_router(incentives.router, prefix="/v1")
app.include_router(inspections.router, prefix="/v1")
app.include_router(departures.router, prefix="/v1")

# Static file serving for uploaded evidence (local dev; use object storage in prod)
_UPLOAD_ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "uploads")
os.makedirs(os.path.join(_UPLOAD_ROOT, "evidence"), exist_ok=True)
app.mount("/uploads", StaticFiles(directory=_UPLOAD_ROOT), name="uploads")

@app.get("/")
async def root():
    return {
        "name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "operational"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": time.time()}

@app.get("/ready")
async def readiness_check():
    try:
        # Check database connection
        from sqlalchemy import text
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"status": "ready"}
    except Exception as e:
        return JSONResponse(
            status_code=503,
            content={"status": "not_ready", "error": str(e)}
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
