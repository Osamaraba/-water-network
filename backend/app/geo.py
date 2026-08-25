"""PostGIS-aware geometry column types.

If the connected database supports PostGIS we use native Geometry columns
(full geofencing / live-map features). Otherwise (e.g. plain Render Postgres,
which has no PostGIS) we fall back to TEXT columns that store WKT strings
(e.g. "POINT(35.9 32.5)") so the rest of the platform - auth, employees,
attendance records, reports, incentives - still runs for real testing.

The availability flag is detected once at import time by attempting to enable
the PostGIS extension on the configured database.
"""
from sqlalchemy import Text

try:
    from geoalchemy2 import Geometry  # type: ignore
    _HAS_GEOALCHEMY = True
except Exception:  # pragma: no cover - geoalchemy2 is a hard dep
    _HAS_GEOALCHEMY = False

POSTGIS_AVAILABLE = False


def _detect_postgis() -> None:
    global POSTGIS_AVAILABLE
    url = _get_database_url()
    if not url or not _HAS_GEOALCHEMY:
        POSTGIS_AVAILABLE = False
        return
    try:
        from sqlalchemy import create_engine, text
        eng = create_engine(url, pool_pre_ping=False)
        with eng.connect() as conn:
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis_topology"))
            conn.commit()
        POSTGIS_AVAILABLE = True
        print("PostGIS extension enabled - using native Geometry columns.")
    except Exception as exc:  # noqa: BLE001
        POSTGIS_AVAILABLE = False
        print(f"WARNING: PostGIS unavailable ({exc}). "
              f"Falling back to TEXT geometry storage (geo features disabled).")


def _get_database_url() -> str:
    try:
        from app.config import get_settings
        return get_settings().DATABASE_URL
    except Exception:
        import os
        return os.environ.get("DATABASE_URL", "")


def _geo(type_name: str, srid: int = 4326):
    if POSTGIS_AVAILABLE and _HAS_GEOALCHEMY:
        return Geometry(type_name, srid=srid)
    return Text()


def point() -> object:
    return _geo("POINT")


def polygon() -> object:
    return _geo("POLYGON")


_detect_postgis()
