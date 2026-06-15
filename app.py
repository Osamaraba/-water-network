"""
app.py — واجهة Streamlit لتطبيق تحليل توزيع المياه الميداني
============================================================
الوظائف:
  - استيراد GIS (KML) واستهلاك (Excel)
  - إدخال ΔH يدوي/جماعي
  - تحليل حسب الأحياء (من KML polygons)
  - مقارنة النظري بالواقعي (شكاوي، طواف)
  - تقارير الفاقد ومناطق الاشتباه
  - حفظ/استعادة الجلسة
"""
import os, json, tempfile, traceback
import requests
from datetime import datetime
from pathlib import Path

import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime, timedelta

# ============================================================
# ربط مع التطبيق الرئيسي (FastAPI)
# ============================================================

MAIN_API_URL = "http://localhost:8002"

def fetch_subscribers_from_main_app():
    """جلب بيانات المشتركين من التطبيق الرئيسي"""
    try:
        response = requests.get(f"{MAIN_API_URL}/subscribers", timeout=5)
        if response.status_code == 200:
            data = response.json()
            df = pd.DataFrame(data)

            # تحويل الإحداثيات إلى geometry (لـ geopandas)
            if 'lat' in df.columns and 'lon' in df.columns:
                from shapely.geometry import Point
                df['geometry'] = df.apply(lambda row: Point(row['lon'], row['lat']), axis=1)

            # إذا كان هناك demand واحد فقط، نحوله إلى الأعمدة الثلاثة المطلوبة
            if 'demand' in df.columns and 'LastMonth' not in df.columns:
                df['LastMonth'] = df['demand']
                df['Avg3Months'] = df['demand']
                df['Avg12Months'] = df['demand']

            return df
    except requests.exceptions.ConnectionError:
        st.warning("⚠️ لا يمكن الاتصال بالتطبيق الرئيسي. تأكد من تشغيل FastAPI على المنفذ 8002")
    except Exception as e:
        st.error(f"خطأ في جلب البيانات: {e}")
    return None

def send_analysis_to_main_app(metrics, results_df):
    """إرسال نتائج التحليل إلى التطبيق الرئيسي (اختياري)"""
    try:
        payload = {
            'metrics': metrics,
            'results': results_df.to_dict('records')
        }
        response = requests.post(f"{MAIN_API_URL}/analysis-results", json=payload, timeout=5)
        return response.status_code == 200
    except:
        return False
import matplotlib.ticker as mticker

from core_analysis import run_analysis, detect_suspicion_zones


def load_from_main_api():
    """محاولة جلب بيانات المشتركين من التطبيق الرئيسي (خادم FastAPI على port 8002)"""
    try:
        resp = requests.get("http://localhost:8002/subscribers", timeout=3)
        if resp.status_code == 200:
            data = resp.json()
            if isinstance(data, list) and len(data) > 0:
                df = pd.DataFrame(data)
                from shapely.geometry import Point
                if "lat" in df.columns and "lon" in df.columns:
                    df["geometry"] = df.apply(
                        lambda r: Point(r["lon"], r["lat"]) if pd.notna(r["lon"]) and pd.notna(r["lat"]) else None, axis=1)
                if "demand" in df.columns and "LastMonth" not in df.columns:
                    df["LastMonth"] = df["demand"]
                    df["Avg3Months"] = df["demand"]
                    df["Avg12Months"] = df["demand"]
                if "elevation" in df.columns and "delta_h" not in df.columns:
                    min_elev = df["elevation"].min()
                    df["delta_h"] = df["elevation"] - min_elev
                if "CustomerID" not in df.columns and "id" in df.columns:
                    df["CustomerID"] = df["id"]
                return df
    except requests.ConnectionError:
        pass
    except Exception as e:
        print(f"load_from_main_api error: {e}")
    return None

# ---------------------------------------------------------------------------
# إعدادات الصفحة
# ---------------------------------------------------------------------------
st.set_page_config(page_title="تحليل توزيع المياه", page_icon="💧", layout="wide")
st.title("💧 نظام تحليل ضخ وتوزيع المياه — الميداني")
st.markdown("---")

# ---------------------------------------------------------------------------
# دوال مساعدة
# ---------------------------------------------------------------------------
SESSION_DIR = Path(tempfile.gettempdir()) / "water_analysis_sessions"
SESSION_DIR.mkdir(parents=True, exist_ok=True)
SESSION_FILE = SESSION_DIR / "session.json"


def _geo_to_records(gdf):
    if gdf is None or (hasattr(gdf, "empty") and gdf.empty):
        return None
    d = gdf.copy()
    if "geometry" in d.columns:
        d["_wkt"] = d["geometry"].apply(
            lambda g: g.wkt if g is not None and not pd.isna(g) else None)
        d = d.drop(columns=["geometry"])
    return d.to_dict(orient="records")


def save_session():
    """حفظ الجلسة كاملة إلى ملف JSON."""
    try:
        pk = st.session_state
        session = dict(
            timestamp=datetime.now().isoformat(),
            q_pump=pk.get("q_pump"),
            h_actual=pk.get("h_actual"),
            selected_cust_id=pk.get("selected_cust_id"),
            excel_name=pk.get("excel_name"),
            customers_records=_geo_to_records(pk.get("customers_gdf")),
            consumption_records=pk.get("consumption_df").to_dict(orient="records")
            if pk.get("consumption_df") is not None else None,
            results_records=pk.get("results_df").to_dict(orient="records")
            if pk.get("results_df") is not None else None,
            metrics=pk.get("metrics"),
        )
        with open(SESSION_FILE, "w", encoding="utf-8") as f:
            json.dump(session, f, ensure_ascii=False, indent=2)
        return True
    except Exception as e:
        st.error(f"فشل حفظ الجلسة: {e}")
        return False


def load_session():
    """قراءة الجلسة من JSON."""
    if SESSION_FILE.exists():
        try:
            with open(SESSION_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return None
    return None


def delete_session():
    if SESSION_FILE.exists():
        SESSION_FILE.unlink()


# ---------------------------------------------------------------------------
# تهيئة حالة Streamlit
# ---------------------------------------------------------------------------
for key in ["customers_gdf", "consumption_df", "results_df", "metrics",
            "q_pump", "h_actual", "selected_cust_id", "excel_name", "actual_status"]:
    if key not in st.session_state:
        st.session_state[key] = None

# ---------------------------------------------------------------------------
# الشريط الجانبي — استيراد البيانات
# ---------------------------------------------------------------------------
with st.sidebar:
    st.header("💾 الجلسة")
    prev = load_session()
    if prev and st.button("🔄 استعادة الجلسة السابقة", use_container_width=True):
        try:
            st.session_state.q_pump = prev.get("q_pump")
            st.session_state.h_actual = prev.get("h_actual")
            st.session_state.selected_cust_id = prev.get("selected_cust_id")
            st.session_state.excel_name = prev.get("excel_name")
            if prev.get("customers_records"):
                import shapely.wkt
                df = pd.DataFrame(prev["customers_records"])
                if "_wkt" in df.columns:
                    df["geometry"] = df["_wkt"].apply(
                        lambda x: shapely.wkt.loads(x) if x else None)
                    df = df.drop(columns=["_wkt"])
                st.session_state.customers_gdf = df
            if prev.get("consumption_records"):
                st.session_state.consumption_df = pd.DataFrame(prev["consumption_records"])
            if prev.get("results_records"):
                st.session_state.results_df = pd.DataFrame(prev["results_records"])
            if prev.get("metrics"):
                st.session_state.metrics = prev["metrics"]
            st.success("✅ تمت الاستعادة")
            st.rerun()
        except Exception as e:
            st.error(f"خطأ في الاستعادة: {e}")

    if st.button("🗑️ جلسة جديدة", use_container_width=True, type="secondary"):
        for key in list(st.session_state.keys()):
            if key != "form_submitted":
                st.session_state[key] = None
        delete_session()
        st.rerun()

    if st.button("📥 تحميل من التطبيق الرئيسي", use_container_width=True, type="secondary"):
        data = load_from_main_api()
        if data is not None:
            st.session_state.customers_gdf = data
            st.success(f"✅ تم تحميل {len(data)} مشترك من التطبيق الرئيسي")
            st.rerun()
        else:
            st.error("❌ لم يتم العثور على بيانات. تأكد من تشغيل التطبيق الرئيسي على port 8002")

    st.markdown("---")

    # -- استيراد KML -------------------------------------------------------
    st.header("🗺️ 1. بيانات المشتركين (KML/KMZ)")
    kml_file = st.file_uploader("اختر ملف KML أو KMZ", type=["kml", "kmz"],
                                key="kml_upload")
    if kml_file and st.session_state.customers_gdf is None:
        import geopandas as gpd
        with st.spinner("جاري قراءة KML..."):
            try:
                original_name = kml_file.name.lower()
                ext = ".kmz" if original_name.endswith(".kmz") else ".kml"
                tmp_path = os.path.join(tempfile.gettempdir(), f"streamlit_kml_{os.urandom(4).hex()}{ext}")
                with open(tmp_path, "wb") as tmp:
                    tmp.write(kml_file.getbuffer())
                if ext == ".kmz":
                    import zipfile
                    if zipfile.is_zipfile(tmp_path):
                        gdf = gpd.read_file(tmp_path)
                    else:
                        gdf = gpd.read_file(tmp_path.replace(".kmz", ".kml"))
                else:
                    gdf = gpd.read_file(tmp_path)
                try:
                    os.unlink(tmp_path)
                except:
                    pass
                if gdf.empty:
                    st.error("الملف فارغ")
                else:
                    # CustomerID
                    if "CustomerID" not in gdf.columns:
                        gdf["CustomerID"] = range(1, len(gdf) + 1)
                    # delta_h بالصفر مؤقتاً
                    if "delta_h" not in gdf.columns:
                        gdf["delta_h"] = 0.0
                    if "name" not in gdf.columns:
                        gdf["name"] = gdf["CustomerID"].astype(str)
                    st.session_state.customers_gdf = gdf
                    st.success(f"✅ {len(gdf)} مشترك")
            except Exception as e:
                st.error(f"❌ خطأ في قراءة الملف: {e}\nتأكد أن الملف KML صحيح (وليس KMZ مضغوط ببرنامج آخر). حاول فتحه بالمفكرة وتأكد من وجود <kml> في أول سطر.")

    if st.session_state.customers_gdf is not None:
        st.info(f"عدد المشتركين: {len(st.session_state.customers_gdf)}")

    # -- إدخال ΔH ----------------------------------------------------------
    st.markdown("---")
    st.header("📏 2. فروق المنسوب (ΔH)")
    dh_method = st.radio("طريقة الإدخال", ["رفع ملف CSV", "قيمة افتراضية"],
                         horizontal=True, label_visibility="collapsed")
    if dh_method == "رفع ملف CSV":
        dh_file = st.file_uploader("ملف CSV (CustomerID, delta_h)",
                                   type=["csv"], key="dh_upload")
        if dh_file and st.button("تطبيق ΔH", key="apply_dh"):
            try:
                dh_df = pd.read_csv(dh_file)
                if "CustomerID" not in dh_df.columns or "delta_h" not in dh_df.columns:
                    st.error("الملف يحتاج عمودي CustomerID و delta_h")
                else:
                    gdf = st.session_state.customers_gdf.copy()
                    gdf = gdf.drop(columns=["delta_h"], errors="ignore")
                    gdf = gdf.merge(dh_df[["CustomerID", "delta_h"]], on="CustomerID", how="left")
                    gdf["delta_h"] = gdf["delta_h"].fillna(0.0)
                    st.session_state.customers_gdf = gdf
                    st.success("✅ تم تطبيق ΔH")
                    st.rerun()
            except Exception as e:
                st.error(f"خطأ: {e}")
    else:
        dh_default = st.number_input("ΔH افتراضي للكل (م)", value=0.0, step=1.0)
        if st.button("تطبيق القيمة الافتراضية", key="apply_dh_def"):
            gdf = st.session_state.customers_gdf.copy()
            gdf["delta_h"] = dh_default
            st.session_state.customers_gdf = gdf
            st.success("✅ تم التعيين")
            st.rerun()

    # -- استيراد Excel الاستهلاك --------------------------------------------
    st.markdown("---")
    st.header("📊 3. بيانات الاستهلاك (Excel)")
    excel_file = st.file_uploader("ملف Excel (CustomerID, LastMonth, Avg3Months, Avg12Months)",
                                  type=["xlsx", "xls"], key="excel_upload")
    if excel_file:
        try:
            cons_df = pd.read_excel(excel_file)
            missing = [c for c in ["CustomerID", "LastMonth", "Avg3Months", "Avg12Months"]
                       if c not in cons_df.columns]
            if missing:
                st.error(f"الأعمدة المفقودة: {missing}")
            else:
                st.session_state.consumption_df = cons_df
                st.session_state.excel_name = excel_file.name
                st.success(f"✅ {len(cons_df)} سجل")
        except Exception as e:
            st.error(f"خطأ: {e}")

    # -- Q pumping ----------------------------------------------------------
    st.markdown("---")
    st.header("🚰 4. كمية الضخ")
    q_pump = st.number_input("Q (م³)", min_value=0.0, value=1000.0, step=100.0)
    st.session_state.q_pump = q_pump

    # -- H actual -----------------------------------------------------------
    st.markdown("---")
    st.header("📍 5. الوصول الفعلي")
    actual_method = st.radio("طريقة", ["ΔH مباشر", "آخر مشترك"],
                             horizontal=True, label_visibility="collapsed")
    h_act = None
    sel_cust = None
    if actual_method == "ΔH مباشر":
        h_act = st.number_input("ΔH الفعلي (م)", value=10.0, step=1.0)
        st.session_state.h_actual = h_act
    else:
        if st.session_state.customers_gdf is not None:
            ids = st.session_state.customers_gdf["CustomerID"].tolist()
            sel_cust = st.selectbox("آخر مشترك وصلته المياه", ids, format_func=lambda x: f"ID {x}")
            st.session_state.selected_cust_id = sel_cust
        else:
            st.warning("استورد بيانات المشتركين أولاً")

    # -- الحالة الفعلية (اختياري) -------------------------------------------
    st.markdown("---")
    st.header("📋 6. الحالة الفعلية (اختياري)")
    st.caption("ارفع ملف CSV: CustomerID, status (وصلت/لم تصل/ضغط ضعيف)")
    actual_file = st.file_uploader("ملف CSV", type=["csv"], key="actual_upload")
    if actual_file:
        try:
            st.session_state.actual_status = pd.read_csv(actual_file)
            st.success("✅ تم الاستيراد")
        except Exception as e:
            st.error(f"خطأ: {e}")

    # -- زر التحليل ---------------------------------------------------------
    st.markdown("---")
    analyze_btn = st.button("🔍 تنفيذ التحليل", type="primary",
                            use_container_width=True)

# ---------------------------------------------------------------------------
# MAIN: تنفيذ التحليل
# ---------------------------------------------------------------------------
if analyze_btn:
    errs = []
    if st.session_state.customers_gdf is None:
        errs.append("بيانات المشتركين (KML)")
    if st.session_state.consumption_df is None:
        errs.append("ملف الاستهلاك (Excel)")
    if st.session_state.q_pump is None or st.session_state.q_pump <= 0:
        errs.append("كمية الضخ Q")

    if errs:
        st.error("❌ الرجاء توفير: " + ", ".join(errs))
    else:
        h_act_val = st.session_state.h_actual if actual_method == "ΔH مباشر" else None
        sel_val = st.session_state.selected_cust_id if actual_method == "آخر مشترك" else None
        with st.spinner("⚙️ جاري التحليل..."):
            try:
                gdf = st.session_state.customers_gdf
                cols = ["CustomerID", "delta_h"]
                if "geometry" in gdf.columns:
                    cols.append("geometry")
                metrics, results = run_analysis(
                    customers_df=gdf[cols],
                    consumption_df=st.session_state.consumption_df,
                    q_pump=st.session_state.q_pump,
                    h_actual=h_act_val,
                    selected_cust_id=sel_val,
                )
                st.session_state.metrics = metrics
                st.session_state.results_df = results

                # مقارنة بالحالة الفعلية (إن وجدت)
                deviation_results = None
                if st.session_state.actual_status is not None:
                    actual = st.session_state.actual_status
                    if "CustomerID" in actual.columns and "status" in actual.columns:
                        deviation_results = results.merge(actual, on="CustomerID", how="left")
                        deviation_results["deviation"] = deviation_results.apply(
                            lambda r: (
                                "اشتباه فاقد/سرقة" if r["served"] == 1
                                and r["status"] in ("لم تصل", "ضغط ضعيف")
                                else "مطابق" if r["served"] == 1 and r["status"] == "وصلت"
                                else "غير مطابق" if r["served"] == 1 and r["status"] != "وصلت"
                                else "—"
                            ), axis=1)
                        st.session_state.deviation_results = deviation_results

                save_session()
                st.success("✅ تم التحليل بنجاح")
            except Exception as e:
                st.error(f"❌ فشل التحليل: {e}\n{traceback.format_exc()}")

# ---------------------------------------------------------------------------
# عرض النتائج
# ---------------------------------------------------------------------------
if st.session_state.metrics and st.session_state.results_df is not None:
    m = st.session_state.metrics
    df = st.session_state.results_df

    st.header("📊 مؤشرات الأداء")
    c1, c2, c3, c4 = st.columns(4)
    with c1:
        st.metric("إجمالي الطلب", f'{m["total_demand_m3"]:,.0f} م³')
        st.metric("كمية الضخ Q", f'{m["pumped_volume_m3"]:,.0f} م³')
    with c2:
        st.metric("الوصول النظري", f'{m["expected_reach_m"]:.1f} م')
        st.metric("الوصول الفعلي", f'{m["actual_reach_m"]:.1f} م')
    with c3:
        st.metric("مؤشر الوصول", f'{m["reach_index"]:.2f}',
                  delta="جيد" if m["reach_index"] >= 0.8 else "ضعيف")
        st.metric("الفجوة", f'{m["gap_m"]:.1f} م')
    with c4:
        st.metric("نسبة الفاقد", f'{m["loss_percent"]:.1f}%',
                  delta="مرتفع" if m["loss_percent"] > 20 else "منخفض")
        st.metric("درجة الاشتباه", f'{m["suspicion_score"]:.2f}',
                  delta="مرتفعة ⚠️" if m["suspicion_score"] > 0.5 else "مقبولة")

    st.markdown("---")

    # منحنى الطلب التراكمي
    st.header("📈 منحنى الطلب التراكمي")
    fig, ax = plt.subplots(figsize=(10, 4.5))
    ax.plot(df["delta_h"], df["cumulative_demand"], "b-", lw=2.5, label="الطلب التراكمي")
    ax.axhline(y=m["pumped_volume_m3"], color="r", ls="--", lw=1.5,
               label=f'Q = {m["pumped_volume_m3"]:,.0f} م³')
    ax.axvline(x=m["expected_reach_m"], color="g", ls=":", lw=1.5,
               label=f'نظري {m["expected_reach_m"]:.1f} م')
    ax.axvline(x=m["actual_reach_m"], color="orange", ls=":", lw=2,
               label=f'فعلي {m["actual_reach_m"]:.1f} م')
    ax.fill_betweenx([0, ax.get_ylim()[1]], m["actual_reach_m"], m["expected_reach_m"],
                     alpha=0.08, color="red", label="فجوة الوصول")
    ax.set_xlabel("ΔH (م)"); ax.set_ylabel("الطلب التراكمي (م³)")
    ax.set_title("منحنى الطلب التراكمي — مقارنة النظري بالفعلي")
    ax.legend(fontsize=9); ax.grid(alpha=0.3)
    st.pyplot(fig)
    plt.close(fig)

    # مناطق الاشتباه
    zones = detect_suspicion_zones(df)
    if zones:
        st.subheader("⚠️ مناطق الاشتباه (فجوة في التغطية)")
        for z in zones:
            st.warning(f'🧩 بين CustomerID {z["start_id"]} و {z["end_id"]}')
    else:
        st.info("✅ لا توجد فجوة — التوزيع مستمر بدون انقطاع")

    # جدول النتائج
    with st.expander("📋 جدول النتائج التفصيلي"):
        show_cols = ["CustomerID", "delta_h", "demand", "cumulative_demand", "served"]
        st.dataframe(df[show_cols], use_container_width=True, height=300)

    # الحالة الفعلية (deviation)
    if st.session_state.get("deviation_results") is not None:
        st.markdown("---")
        st.header("📋 مقارنة النظري بالواقعي")
        dev = st.session_state.deviation_results
        sus_count = len(dev[dev["deviation"] == "اشتباه فاقد/سرقة"])
        st.metric("حالات الاشتباه", sus_count)
        st.dataframe(dev[["CustomerID", "delta_h", "served", "status", "deviation"]],
                     use_container_width=True, height=300)

    # تصدير
    st.markdown("---")
    st.subheader("💾 تصدير")
    col_a, col_b = st.columns(2)
    with col_a:
        csv = df.to_csv(index=False).encode("utf-8")
        st.download_button("📥 CSV", csv,
                           f"water_analysis_{datetime.now():%Y%m%d_%H%M}.csv",
                           "text/csv", use_container_width=True)
    with col_b:
        if st.button("💾 حفظ الجلسة", use_container_width=True):
            if save_session():
                st.success("تم الحفظ ✓")

else:
    st.info("👈 أدخل البيانات في الشريط الجانبي واضغط **🔍 تنفيذ التحليل**")

st.markdown("---")
st.caption("💧 نظام تحليل ضخ وتوزيع المياه ميداني | يعمل بدون إنترنت بعد تثبيت المكتبات")
