import React, { useState, useRef, useCallback, useEffect } from "react";
import * as XLSX from "xlsx";
import MapView from "./components/MapView";
import { NamedZone, AnalysisResult } from "./types";
import { PipeLine } from "./components/DrawingTool";
import StatusTable from "./components/StatusTable";
import LiveChart from "./components/LiveChart";
import ProgressChart from "./components/ProgressChart";
import ControlPanel from "./components/ControlPanel";
import Summary from "./components/Summary";
import AnalysisPanel from "./components/AnalysisPanel";
import { useWebSocket } from "./hooks/useWebSocket";
import { Subscriber, SimulationConfig, Connection } from "./types";


const NAMES_AR = [
  "عبدالله", "محمد", "أحمد", "علي", "خالد", "فهد", "سعد", "ناصر", "حسن", "حسين",
  "إبراهيم", "عمر", "ماجد", "بدر", "سلطان", "فيصل", "تركي", "مشعل", "بندر", "سامي",
  "ياسر", "وائل", "هاني", "طارق", "أيمن", "جابر", "موسى", "يوسف", "إسماعيل", "زياد",
  "راشد", "نايف", "مبارك", "هاشم", "شادي", "أديب", "عصام", "حازم", "كمال", "جمال",
  "أنور", "منصور", "شريف", "كرم", "بسام", "رامي", "عزام", "مهند", "أوس", "ليث"
];

const generateSample = (count: number): Subscriber[] => {
  const results: Subscriber[] = [];
  for (let i = 0; i < count; i++) {
    const elev = 300 + Math.random() * 150;
    const demand = 100 + Math.random() * 900;
    results.push({
      id: i + 1,
      name: NAMES_AR[i % NAMES_AR.length] + (i >= NAMES_AR.length ? ` ${Math.floor(i / NAMES_AR.length) + 1}` : ""),
      elevation: Math.round(elev * 100) / 100,
      demand: Math.round(demand * 100) / 100,
      qmax: Math.round((5 + Math.random() * 20) * 100) / 100,
      received: 0,
      completed: false,
      arrival_time: null,
      completion_time: null,
      fill_percent: 0,
      lat: 24.65 + Math.random() * 0.15,
      lon: 46.62 + Math.random() * 0.15,
    });
  }
  return results;
};

const SAVE_KEY = "ws_project";

function loadSaved<T>(key: string): T[] {
  try { const d = localStorage.getItem(key); return d ? JSON.parse(d) : []; } catch { return []; }
}
function saveData(key: string, data: any) {
  try { localStorage.setItem(key, JSON.stringify(data)); } catch (e) { console.error("saveData:", e); }
}

class ErrorBoundary extends React.Component<{children: React.ReactNode}, {hasError: boolean}> {
  state = { hasError: false };
  static getDerivedStateFromError() { return { hasError: true }; }
  render() {
    return this.state.hasError
      ? <div style={{padding:20,background:"#ffebee",color:"#c62828"}}>حدث خطأ غير متوقع. الرجاء تحديث الصفحة وحفظ المشروع بشكل دوري.</div>
      : this.props.children;
  }
}

const App: React.FC = () => {
  const [subscribers, setSubscribers] = useState<Subscriber[]>(() => loadSaved<Subscriber>(SAVE_KEY + "_subs").map((s: any) => ({ ...s, received: 0, fill_percent: 0, completed: false, arrival_time: null, completion_time: null })));
  const { lastStep, steps, error, startSimulation, isFinished, resetSimulation, sendCommand } = useWebSocket();
  const [uploading, setUploading] = useState(false);
  const [zones, setZones] = useState<NamedZone[]>(() => loadSaved(SAVE_KEY + "_zones"));
  const [activeZoneId, setActiveZoneId] = useState<string | null>(null);
  const [pipes, setPipes] = useState<PipeLine[]>(() => loadSaved(SAVE_KEY + "_pipes").map((p: any) => ({ id: p.id, latlngs: p.latlngs })));
  const [connections, setConnections] = useState<Connection[]>(() => loadSaved(SAVE_KEY + "_conns"));
  const fileRef = useRef<HTMLInputElement>(null);
  const projectRef = useRef<HTMLInputElement>(null);
  const [mode, setMode] = useState<"simulation" | "analysis">("simulation");
  const [zonePumpVolumes, setZonePumpVolumes] = useState<Record<string, number>>({});
  const [analysisResults, setAnalysisResults] = useState<AnalysisResult[]>([]);

  useEffect(() => { localStorage.removeItem("water_sim_subs"); localStorage.removeItem("water_sim_pipes"); localStorage.removeItem("water_sim_zones"); }, []);
  const saveNow = useCallback(() => {
    const clean = subscribers.map(s => ({ id: s.id, name: s.name, lat: s.lat !== null ? +s.lat.toFixed(5) : null, lon: s.lon !== null ? +s.lon.toFixed(5) : null, elevation: Math.round(s.elevation), demand: s.demand, qmax: s.qmax }));
    saveData(SAVE_KEY + "_subs", clean);
    saveData(SAVE_KEY + "_pipes", pipes.map(p => ({ id: p.id, latlngs: p.latlngs })));
    saveData(SAVE_KEY + "_zones", zones);
    saveData(SAVE_KEY + "_conns", connections);
  }, [subscribers, pipes, zones, connections]);
  useEffect(() => { const h = () => saveNow(); window.addEventListener("beforeunload", h); return () => window.removeEventListener("beforeunload", h); }, [saveNow]);

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files?.length) return;
    saveNow();
    setUploading(true);
    try {
      const buf = await e.target.files[0].arrayBuffer();
      const wb = XLSX.read(buf, { type: "array" });
      const ws = wb.Sheets[wb.SheetNames[0]];
      const rows: any[] = XLSX.utils.sheet_to_json(ws, { defval: "" });
      const COL_MAP: Record<string, string> = {
        "name": "name", "الاسم": "name", "اسم": "name",
        "elevation": "elevation", "ارتفاع": "elevation", "الارتفاع": "elevation", "منسوب": "elevation",
        "demand": "demand", "الطلب": "demand", "طلب": "demand", "استهلاك": "demand",
        "qmax": "qmax", "معدل تصريف العوامه": "qmax", "تصريف العوامه": "qmax", "سعة": "qmax",
        "lat": "lat", "خط العرض": "lat", "latitude": "lat", "عرض": "lat",
        "lon": "lon", "خط الطول": "lon", "longitude": "lon", "طول": "lon",
      };
      const headers = Object.keys(rows[0] || {});
      const mapped: Record<string, string> = {};
      for (const h of headers) {
        const key = (h as string).trim().toLowerCase();
        if (COL_MAP[key]) mapped[COL_MAP[key]] = h;
      }
      const missing = ["name", "elevation", "demand", "qmax"].filter(k => !mapped[k]);
      if (missing.length) { alert(`الأعمدة المطلوبة: ${missing.join(", ")}`); return; }
      const subs: Subscriber[] = rows.map((row: any, i: number) => {
        const lat = row[mapped["lat"]] ? parseFloat(row[mapped["lat"]]) : null;
        const lon = row[mapped["lon"]] ? parseFloat(row[mapped["lon"]]) : null;
        return {
          id: i + 1,
          name: String(row[mapped["name"]]),
          elevation: parseFloat(row[mapped["elevation"]]) || 0,
          demand: parseFloat(row[mapped["demand"]]) || 0,
          qmax: parseFloat(row[mapped["qmax"]]) || 0,
          received: 0, fill_percent: 0, completed: false, arrival_time: null, completion_time: null,
          lat, lon,
        };
      });
      if (subs.length === 0) { alert("الملف لا يحتوي على بيانات"); return; }
      setSubscribers(subs);
      alert(`تم استيراد ${subs.length} مشترك بنجاح`);
    } catch (err) {
      alert("خطأ في قراءة الملف: " + (err as any).message);
    } finally {
      setUploading(false);
      e.target.value = "";
    }
  };

  const handleSaveToFile = () => {
    const clean = subscribers.map(s => ({
      id: s.id, name: s.name, lat: s.lat !== null ? +s.lat.toFixed(5) : null,
      lon: s.lon !== null ? +s.lon.toFixed(5) : null, elevation: Math.round(s.elevation),
      demand: s.demand, qmax: s.qmax
    }));
    const data = JSON.stringify({ subscribers: clean, pipes: pipes.map(p => ({ id: p.id, latlngs: p.latlngs })), zones, connections }, null, 2);
    const blob = new Blob([data], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "مشروع_المياه.wsm";
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleLoadFromFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
      try {
        const data = JSON.parse(ev.target?.result as string);
        if (data.subscribers) setSubscribers(data.subscribers.map((s: any) => ({
          ...s, received: 0, fill_percent: 0, completed: false, arrival_time: null, completion_time: null
        })));
        if (data.pipes) setPipes(data.pipes.map((p: any) => ({ id: p.id, latlngs: p.latlngs })));
        if (data.zones) setZones(data.zones);
        if (data.connections) setConnections(data.connections);
      } catch (err) {
        alert("خطأ في قراءة الملف");
      }
    };
    reader.readAsText(file);
    e.target.value = "";
  };

  const handleStart = (cfg: SimulationConfig, subs: Subscriber[]) => {
    if (!subs.length) { alert("الرجاء رفع ملف Excel أولاً"); return; }
    const enriched = subs.map(s => {
      const connEl = connections.find(c => c.subId === s.id)?.elevation;
      return { ...s, connection_elevation: connEl ?? null };
    });
    startSimulation(cfg, enriched as any);
  };

  const current = lastStep?.subscribers || subscribers;
  const activeId = lastStep?.active_subscriber_id ?? null;

  return (
    <ErrorBoundary>
    <div style={{ direction: "rtl", padding: 20 }}>
      <h1>محاكاة توزيع المياه</h1>
      <details style={{ marginBottom: 6, fontSize: 13, background: "#f5f5f5", padding: "0 10px", borderRadius: 4, cursor: "pointer" }}>
        <summary style={{ padding: "6px 0", fontWeight: "bold" }}>📖 دليل الاستخدام</summary>
        <div style={{ padding: "4px 0 10px 0", lineHeight: 1.7 }}>
          <b>🔹 رفع بيانات المشتركين:</b> اختر ملف Excel (xlsx) — الأعمدة: الاسم، خط الطول (lon)، خط العرض (lat)، الطلب (m³)، Qmax.
          <br /><b>🔹 استيراد KML/KMZ:</b> النقاط ← مشتركين، الخطوط ← شبكة مياه، المضلعات ← أحياء.
          <br /><b>🔹 رسم شبكة:</b> ✏️ خط مياه (انقر مزدوج للإنهاء) | 🔲 تحديد حي (انقر مزدوج للإنهاء).
          <br /><b>🔹 ربط المشتركين:</b> 🔗 ربط تلقائي يربط الكل بأقرب خط | ✏️ ربط يدوي: اضغط مشترك ثم الخريطة.
          <br /><b>🔹 تعديل/حذف ربط:</b> ✏️ ربط يدوي → اضغط على مشترك مربوط ← يُحذف الربط.
          <br /><b>🔹 جلب ارتفاعات:</b> 🏔️ ارتفاعات — يجلب ارتفاع المشتركين ونقاط الربط من API خارجي.
          <br />          <b>🔹 المحاكاة:</b> اضبط المعاملات في لوحة التحكم ثم اضغط "بدء المحاكاة" (شغّل ملف <b>شغل_الباكند.bat</b> أولاً).
          <br /><b>🔹 تحكم أثناء المحاكاة:</b> ⏹ إيقاف الضخ | ▶ تشغيل الضخ | تعديل q_in مباشرة.
          <br /><b>🔹 حفظ المشروع:</b> 💾 حفظ إلى ملف (.wsm) | 📂 فتح ملف لاسترجاعه لاحقاً.
          <br /><b>🔹 التحليل الذكي:</b> اضغط "🔬 تحليل ذكي" — رتب المشتركين بـ ΔH، حدد Q لكل حي، راقب WI في المخطط والأعمدة، أدخل الحالة الفعلية لاكتشاف الفاقد.
          <br /><b>🔹 حفظ تلقائي:</b> البيانات تُحفظ في المتصفح وتستعاد عند تحديث الصفحة.
        </div>
      </details>
      <div style={{ display: "flex", gap: 10, alignItems: "center", marginBottom: 10, flexWrap: "wrap" }}>
        <input ref={fileRef} type="file" accept=".xlsx,.xls" onChange={handleUpload} disabled={uploading} />
        {uploading && <span>جاري الرفع...</span>}
        {subscribers.length > 0 && !uploading && <span>تم تحميل {subscribers.length} مشترك</span>}
        <button onClick={handleSaveToFile} style={{ padding: "4px 12px", background: "#0d47a1", color: "white", border: "none", borderRadius: 4 }}>
          💾 حفظ إلى ملف
        </button>
        <input ref={projectRef} type="file" accept=".wsm" onChange={handleLoadFromFile} style={{ display: "none" }} />
        <button onClick={() => projectRef.current?.click()} style={{ padding: "4px 12px", background: "#e65100", color: "white", border: "none", borderRadius: 4 }}>
          📂 فتح ملف
        </button>
        <button onClick={() => setSubscribers(generateSample(50))} style={{ padding: "4px 12px" }}>
          معاينة
        </button>
        {subscribers.length > 0 && (
          <button onClick={() => { setSubscribers([]); setPipes([]); setZones([]); setConnections([]); }} style={{ padding: "4px 12px" }}>
            إعادة تعيين
          </button>
        )}
        {error && <span style={{ color: "red" }}>{error}</span>}
        {isFinished && <span style={{ color: "green" }}>اكتملت المحاكاة بنجاح</span>}
        <ControlPanel onStart={handleStart} subscribers={subscribers} isRunning={steps.length > 0 && !isFinished && !error} />
        {steps.length > 0 && !isFinished && !error && (
          <span style={{ display: "flex", gap: 4, alignItems: "center" }}>
            <button onClick={() => sendCommand("stop_pump")} style={{ padding: "2px 8px", background: "#d32f2f", color: "white", border: "none", borderRadius: 4, fontSize: 11 }}>⏹ إيقاف الضخ</button>
            <button onClick={() => sendCommand("start_pump")} style={{ padding: "2px 8px", background: "#2e7d32", color: "white", border: "none", borderRadius: 4, fontSize: 11 }}>▶ تشغيل الضخ</button>
            <label style={{ fontSize: 11 }}>q_in: <input type="number" defaultValue={200} step={10} onBlur={e => sendCommand("set_qin", parseFloat(e.target.value) || 0)} style={{ width: 60, fontSize: 11 }} /> م³/س</label>
          </span>
        )}
        <button onClick={() => setMode(mode === "simulation" ? "analysis" : "simulation")} style={{ padding: "4px 12px", background: mode === "analysis" ? "#1565c0" : "#78909c", color: "white", border: "none", borderRadius: 4 }}>
          {mode === "analysis" ? "⚙️ محاكاة هيدروليكية" : "🔬 تحليل ذكي"}
        </button>
      </div>
      <MapView subscribers={current} activeId={activeId} pipes={pipes} onPipesChange={(p) => { saveNow(); setPipes(p); }} initialZones={zones} connections={connections} onConnectionsChange={(c) => { saveNow(); setConnections(c); }} onKmlSubscribers={(subs) => { saveNow(); setSubscribers(prev => [...prev, ...subs]); }} onZonesChange={(z) => { saveNow(); setZones(z); }} onElevationsUpdate={(elevs) => { saveNow(); setSubscribers(prev => prev.map(s => { const e = elevs.find(x => x.id === s.id); return e ? { ...s, elevation: e.elevation } : s; })); }} />
      {mode === "analysis" ? (
        <AnalysisPanel subscribers={subscribers} zones={zones} onUpdateSubscriber={(id, field, val) => { setSubscribers(prev => prev.map(s => s.id === id ? { ...s, [field]: val } : s)); }} zonePumpVolumes={zonePumpVolumes} onZonePumpChange={(zoneId, q) => setZonePumpVolumes(prev => ({ ...prev, [zoneId]: q }))} setAnalysisResults={setAnalysisResults} />
      ) : (
      <><StatusTable subscribers={current} activeId={activeId} activeZoneId={activeZoneId} onZoneFilterChange={setActiveZoneId} zones={zones} onUpdateSubscriber={(id, field, val) => { setSubscribers(prev => prev.map(s => s.id === id ? { ...s, [field]: val } : s)); resetSimulation(); }} />
      <LiveChart steps={steps} />
      <ProgressChart steps={steps} />
      {lastStep && (
        <div style={{ marginTop: 8 }}>
          الزمن: {lastStep.time.toFixed(2)} ساعة &nbsp;|&nbsp;
          مستوى الماء: {lastStep.water_level.toFixed(2)} م &nbsp;|&nbsp;
          التقدم: {(lastStep.progress * 100).toFixed(1)}%
        </div>
      )}
      {isFinished && lastStep && <Summary subscribers={lastStep.subscribers} />}
      </>
      )}
    </div>
    </ErrorBoundary>
  );
};
export default App;