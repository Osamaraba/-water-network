"""
core_analysis.py — المحرك التحليلي لتوزيع المياه
===============================================
يعتمد على:
  1. ترتيب المشتركين تصاعدياً حسب فرق المنسوب (ΔH)
  2. الطلب التراكمي ← منحنى الطلب
  3. إسقاط كمية الضخ Q على المنحنى لإيجاد H_expected
  4. مقارنة H_expected مع H_actual (من واقع الميدان)
  5. تصنيف المخدومين، حساب الفاقد، درجة الاشتباه
"""
import numpy as np
import pandas as pd
from typing import Optional, Tuple


def calc_weighted_demand(row: pd.Series) -> float:
    """الطلب الموزون = 0.5×LastMonth + 0.3×Avg3 + 0.2×Avg12"""
    return 0.5 * row["LastMonth"] + 0.3 * row["Avg3Months"] + 0.2 * row["Avg12Months"]


def expected_reach(df: pd.DataFrame, q_pump: float) -> float:
    """
    استيفاء خطي لإيجاد ΔH النظري لكمية الضخ q_pump.
    الـ df مفروض مرتب تصاعدياً حسب delta_h وعنده عمود cumulative_demand.
    """
    if len(df) == 0:
        return 0.0
    cum = df["cumulative_demand"].values
    dh = df["delta_h"].values
    if q_pump <= cum[0]:
        return float(dh[0])
    if q_pump >= cum[-1]:
        return float(dh[-1])
    idx = np.searchsorted(cum, q_pump, side="right") - 1
    idx = max(0, min(idx, len(df) - 2))
    frac = (q_pump - cum[idx]) / (cum[idx + 1] - cum[idx]) if cum[idx + 1] > cum[idx] else 0
    return float(dh[idx] + frac * (dh[idx + 1] - dh[idx]))


def classify_served(df: pd.DataFrame, h_actual: float) -> pd.DataFrame:
    """يضيف عمود served: 1 إذا delta_h ≤ h_actual"""
    df = df.copy()
    df["served"] = (df["delta_h"] <= h_actual).astype(int)
    return df


def compute_metrics(df: pd.DataFrame, q_pump: float, h_exp: float, h_act: float) -> dict:
    """جميع مؤشرات الأداء"""
    total_demand = float(df["demand"].sum())
    served_mask = df["served"] == 1
    served_demand = float(df.loc[served_mask, "demand"].sum())
    loss_vol = max(0.0, q_pump - served_demand)
    loss_pct = (loss_vol / q_pump * 100) if q_pump > 0 else 0.0
    reach_idx = (h_act / h_exp) if h_exp > 0 else 0.0
    gap = h_exp - h_act
    gap_ratio = (gap / h_exp) if h_exp > 0 else 0.0
    loss_ratio = (loss_vol / q_pump) if q_pump > 0 else 0.0
    # 40% من فجوة الوصول + 30% من نسبة الفاقد + 30% من (1-مؤشر الوصول)
    suspicion_score = 0.4 * gap_ratio + 0.3 * loss_ratio + 0.3 * (1 - min(reach_idx, 1))
    return dict(
        total_demand_m3=round(total_demand, 1),
        pumped_volume_m3=round(q_pump, 1),
        expected_reach_m=round(h_exp, 2),
        actual_reach_m=round(h_act, 2),
        reach_index=round(reach_idx, 3),
        gap_m=round(gap, 2),
        loss_volume_m3=round(loss_vol, 1),
        loss_percent=round(loss_pct, 1),
        suspicion_score=round(suspicion_score, 3),
        served_customers=int(df["served"].sum()),
        total_customers=len(df),
    )


def detect_suspicion_zones(df: pd.DataFrame) -> list:
    """
    يكتشف مناطق الاشتباه: سلسلة من المشتركين المخدومين نظرياً
    لكن بينهم مشترك غير مخدوم (فجوة في التغطية).
    المخرجات: قائمة dictionaries {start_id, end_id, start_dh, end_dh}
    """
    zones = []
    in_gap = False
    gap_start = None
    for _, row in df.iterrows():
        if row["served"] == 0 and not in_gap:
            in_gap = True
            gap_start = row["CustomerID"]
        elif row["served"] == 1 and in_gap:
            zones.append(dict(start_id=gap_start, end_id=row["CustomerID"]))
            in_gap = False
    return zones


def run_analysis(
    customers_df: pd.DataFrame,
    consumption_df: pd.DataFrame,
    q_pump: float,
    h_actual: Optional[float] = None,
    selected_cust_id: Optional[int] = None,
) -> Tuple[dict, pd.DataFrame]:
    """
    تنفيذ التحليل الكامل.
    
    المعاملات
    ----------
    customers_df : DataFrame
       必须 يحتوي على أعمدة: CustomerID, delta_h, (اختياري geometry, lat, lon)
    consumption_df : DataFrame
       必须 يحتوي على: CustomerID, LastMonth, Avg3Months, Avg12Months
    q_pump : float — كمية الضخ (م³)
    h_actual : float أو None — ΔH الفعلي للوصول (من الميدان)
    selected_cust_id : int أو None — CustomerID آخر مشترك وصلته المياه
    
    المخرجات
    --------
    (metrics_dict, results_df)
    """
    # التحقق من الأعمدة المطلوبة
    for col in ["CustomerID", "delta_h"]:
        if col not in customers_df.columns:
            raise ValueError(f"customers_df يفتقد العمود: {col}")
    for col in ["CustomerID", "LastMonth", "Avg3Months", "Avg12Months"]:
        if col not in consumption_df.columns:
            raise ValueError(f"consumption_df يفتقد العمود: {col}")

    # دمج
    merged = customers_df.merge(consumption_df, on="CustomerID", how="inner")
    if merged.empty:
        raise ValueError("لا يوجد تطابق في CustomerID بين الملفين")

    # طلب موزون
    merged["demand"] = merged.apply(calc_weighted_demand, axis=1)
    merged = merged.sort_values("delta_h").reset_index(drop=True)
    merged["cumulative_demand"] = merged["demand"].cumsum()

    # ΔH النظري
    h_exp = expected_reach(merged, q_pump)

    # ΔH الفعلي
    if h_actual is not None:
        h_act = float(h_actual)
    elif selected_cust_id is not None:
        row = merged[merged["CustomerID"] == selected_cust_id]
        if row.empty:
            raise ValueError(f"المشترك {selected_cust_id} غير موجود")
        h_act = float(row["delta_h"].iloc[0])
    else:
        raise ValueError("يجب تزويد h_actual أو selected_cust_id")

    if h_act <= 0:
        h_act = merged["delta_h"].min()

    # تصنيف
    merged = classify_served(merged, h_act)

    # مؤشرات
    metrics = compute_metrics(merged, q_pump, h_exp, h_act)
    metrics["suspicion_zones"] = detect_suspicion_zones(merged)

    return metrics, merged
