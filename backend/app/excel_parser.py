import pandas as pd
from typing import List
from .models import SubscriberInput

COLUMN_MAP = {
    "name": "name", "الاسم": "name", "اسم": "name", "subscriber": "name",
    "elevation": "elevation", "ارتفاع": "elevation", "الارتفاع": "elevation", "منسوب": "elevation",
    "demand": "demand", "الطلب": "demand", "طلب": "demand", "استهلاك": "demand",
    "qmax": "qmax", "معدل تصريف العوامه": "qmax", "تصريف العوامه": "qmax", "qmax": "qmax", "سعة": "qmax",
    "lat": "lat", "خط العرض": "lat", "latitude": "lat", "عرض": "lat",
    "lon": "lon", "خط الطول": "lon", "longitude": "lon", "long": "lon", "طول": "lon",
}

def parse_excel_to_subscribers(df: pd.DataFrame) -> List[SubscriberInput]:
    subscribers = []
    df.columns = df.columns.str.strip()
    mapped = {}
    for col in df.columns:
        cl = col.strip().lower()
        if cl in COLUMN_MAP:
            mapped[COLUMN_MAP[cl]] = col

    required = {"name", "elevation", "demand", "qmax"}
    missing = required - set(mapped.keys())
    if missing:
        raise ValueError(f"Excel must contain columns: {missing}")

    for idx, row in df.iterrows():
        sub = SubscriberInput(
            name=str(row[mapped["name"]]),
            elevation=float(row[mapped["elevation"]]),
            demand=float(row[mapped["demand"]]),
            qmax=float(row[mapped["qmax"]]),
            lat=float(row[mapped["lat"]]) if "lat" in mapped and pd.notna(row[mapped["lat"]]) else None,
            lon=float(row[mapped["lon"]]) if "lon" in mapped and pd.notna(row[mapped["lon"]]) else None,
        )
        subscribers.append(sub)
    return subscribers
