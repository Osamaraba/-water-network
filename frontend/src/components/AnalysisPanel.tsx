import React, { useState, useMemo, useRef } from "react";
import * as XLSX from "xlsx";
import { BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid, ResponsiveContainer, Legend } from "recharts";
import { Subscriber, NamedZone, AnalysisResult } from "../types";

interface AnalysisPanelProps {
  subscribers: Subscriber[];
  zones: NamedZone[];
  onUpdateSubscriber: (id: number, field: string, value: number) => void;
  zonePumpVolumes: Record<string, number>;
  onZonePumpChange: (zoneId: string, q: number) => void;
  setAnalysisResults: (results: AnalysisResult[]) => void;
}

type ActualStatus = "وصلت" | "ضغط ضعيف" | "لم تصل" | "لم يُعرف";

const DEFAULT_ZONE_Q: Record<string, number> = {};

const AnalysisPanel: React.FC<AnalysisPanelProps> = ({ subscribers, zones, onUpdateSubscriber, zonePumpVolumes, onZonePumpChange, setAnalysisResults }) => {
  const [alpha, setAlpha] = useState(0.01);
  const [qIn, setQIn] = useState(100);
  const [pumpHours, setPumpHours] = useState(5);
  const thresholdLow = 0.3;
  const thresholdHigh = 0.5;
  const [actualStatus, setActualStatus] = useState<Record<number, ActualStatus>>({});
  const [zoneFilter, setZoneFilter] = useState<string | null>(null);
  const [selectedZoneQ, setSelectedZoneQ] = useState<string | null>(null);
  const dhRef = useRef<HTMLInputElement>(null);
  const consRef = useRef<HTMLInputElement>(null);

  const effectiveZones = useMemo(() => {
    if (zones.length === 0) {
      return [{ id: "__all__", name: "جميع المشتركين", subscriberIds: subscribers.map(s => s.id), latlngs: [] as [number, number][] }];
    }
    return zones;
  }, [zones, subscribers]);

  const currentZone = zoneFilter ? effectiveZones.find(z => z.id === zoneFilter) || effectiveZones[0] : effectiveZones[0];

  const filtered = useMemo(() => {
    return subscribers.filter(s => currentZone.subscriberIds.includes(s.id));
  }, [subscribers, currentZone]);

  const zoneMinElev = useMemo(() => {
    if (filtered.length === 0) return 0;
    return Math.min(...filtered.map(s => s.elevation));
  }, [filtered]);

  const sorted = useMemo(() => {
    return [...filtered].map(s => ({ ...s, _dh: s.deltaH ?? (s.elevation - zoneMinElev) }))
      .sort((a, b) => a._dh - b._dh);
  }, [filtered, zoneMinElev]);

  const totalDemand = useMemo(() => sorted.reduce((s, sub) => s + sub.demand, 0), [sorted]);
  const zoneQ = qIn * pumpHours;
  const coverage = totalDemand > 0 ? Math.min(zoneQ / totalDemand, 1) : 0;

  React.useEffect(() => { onZonePumpChange(currentZone.id, zoneQ); }, [qIn, pumpHours, currentZone.id]);

  const results = useMemo(() => {
    return sorted.map(sub => {
      const h = Math.max(sub._dh, 1);
      const supply = sub.demand * coverage;
      const wi = supply / (1 + alpha * h);
      let status: "served" | "partial" | "not-served";
      if (wi >= thresholdHigh) status = "served";
      else if (wi >= thresholdLow) status = "partial";
      else status = "not-served";
      const actual = actualStatus[sub.id] || "لم يُعرف";
      let deviation = 0;
      if (status === "served" && actual === "لم تصل") deviation = -1;
      else if (status === "not-served" && actual === "وصلت") deviation = 1;
      return { subId: sub.id, deltaH: sub._dh, demand: sub.demand, supply, wi, status, actualStatus: actual, deviation };
    });
  }, [sorted, coverage, alpha, thresholdLow, thresholdHigh, actualStatus]);

  React.useEffect(() => { setAnalysisResults(results); }, [results, setAnalysisResults]);

  const served = results.filter(r => r.status === "served");
  const partial = results.filter(r => r.status === "partial");
  const notServed = results.filter(r => r.status === "not-served");
  const actualServed = results.filter(r => r.actualStatus === "وصلت");

  const maxServedH = served.length > 0 ? Math.max(...served.map(r => r.deltaH)) : 0;

  const suspicionZones = useMemo(() => {
    const out: { start: number; end: number }[] = [];
    let start: number | null = null;
    for (const r of results) {
      if (r.status === "served" && (r.actualStatus === "لم تصل" || r.actualStatus === "ضغط ضعيف")) {
        if (start === null) start = r.subId;
      } else if (r.status === "not-served" && start !== null) {
        out.push({ start, end: r.subId });
        start = null;
      }
    }
    return out;
  }, [results]);

  const lossPercent = zoneQ > 0 ? ((zoneQ - actualServed.reduce((s, r) => s + r.demand, 0)) / zoneQ * 100) : 0;

  const handleElevationFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files?.length) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
      try {
        const wb = XLSX.read(ev.target?.result as ArrayBuffer, { type: "array" });
        const ws = wb.Sheets[wb.SheetNames[0]];
        const rows: any[] = XLSX.utils.sheet_to_json(ws, { defval: "" });
        for (const row of rows) {
          const id = parseInt(row["Customer ID"] || row["customer_id"] || row["id"] || row["رقم"] || row["المعرف"] || row["كود"]) || 0;
          const h = parseFloat(row["ΔH"] || row["deltaH"] || row["Elevation Difference"] || row["فرق المنسوب"] || row["ΔH"]) || 0;
          if (id) onUpdateSubscriber(id, "deltaH", h);
        }
        alert("تم استيراد فرق المنسوب");
      } catch (err) { alert("خطأ: " + (err as any).message); }
    };
    reader.readAsArrayBuffer(e.target.files[0]);
    e.target.value = "";
  };

  const handleConsumptionFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files?.length) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
      try {
        const wb = XLSX.read(ev.target?.result as ArrayBuffer, { type: "array" });
        const ws = wb.Sheets[wb.SheetNames[0]];
        const rows: any[] = XLSX.utils.sheet_to_json(ws, { defval: "" });
        for (const row of rows) {
          const id = parseInt(row["Customer ID"] || row["customer_id"] || row["id"] || row["رقم"] || row["المعرف"]) || 0;
          const cons = parseFloat(row["Monthly Consumption"] || row["consumption"] || row["Average"] || row["الاستهلاك"] || row["الشهري"] || row["المعدل"]) || 0;
          if (id) onUpdateSubscriber(id, "demand", cons);
        }
        alert("تم استيراد الاستهلاك الشهري");
      } catch (err) { alert("خطأ: " + (err as any).message); }
    };
    reader.readAsArrayBuffer(e.target.files[0]);
    e.target.value = "";
  };

  const statusStyle = (s: string) => {
    if (s === "served") return { color: "#1f77b4", bg: "#e3f2fd" };
    if (s === "partial") return { color: "#e65100", bg: "#fff3e0" };
    return { color: "#d32f2f", bg: "#ffebee" };
  };

  return (
    <div style={{ marginTop: 10, padding: 10, border: "1px solid #1565c0", borderRadius: 8 }}>
      <h3 style={{ margin: "0 0 8px 0" }}>🔬 تحليل توزيع المياه الذكي</h3>

      <details style={{ fontSize: 12, marginBottom: 8, background: "#f5f5f5", padding: "4px 8px", borderRadius: 4 }}>
        <summary style={{ cursor: "pointer" }}>كيف يعمل مؤشر WI؟</summary>
        <div style={{ padding: "4px 8px", lineHeight: 1.8 }}>
          <b>WI (مؤشر وصول الماء)</b> = الحصة ÷ (1 + α × ΔH)<br />
          <b>الكمية الكلية Q</b> = تدفق المضخة (م³/س) × عدد ساعات الضخ<br />
          <b>نسبة التغطية</b> = Q ÷ إجمالي الاستهلاك في الحي<br />
          <b>الحصة</b> = استهلاك المشترك × نسبة التغطية<br />
          <b>تأثير المنسوب:</b> كلما زاد ΔH، زادت مقاومة وصول الماء ← WI يقل.<br />
          <b>α</b> يضبط شدة تأثير المنسوب: α صغير (0.001) ← المنسوب يكاد لا يؤثر | α كبير (0.05) ← فقط المنخفضات تخدم.<br />
          العتبات: WI ≥ 0.5 ← <span style={{ color: "#1f77b4" }}>✅ مخدوم</span> | WI ≥ 0.3 ← <span style={{ color: "#e65100" }}>⚠️ جزئي</span> | WI &lt; 0.3 ← <span style={{ color: "#d32f2f" }}>❌ غير مخدوم</span>.
        </div>
      </details>

      <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginBottom: 8 }}>
        <input ref={dhRef} type="file" accept=".xlsx,.xls,.csv" onChange={handleElevationFile} style={{ fontSize: 11 }} />
        <input ref={consRef} type="file" accept=".xlsx,.xls,.csv" onChange={handleConsumptionFile} style={{ fontSize: 11 }} />
      </div>

      <div style={{ display: "flex", gap: 15, flexWrap: "wrap", alignItems: "center", marginBottom: 8 }}>
        <label title="تأثير فرق المنسوب على وصول الماء (0 = لا تأثير)">تأثير المنسوب α: <input type="number" step="0.001" value={alpha} onChange={e => setAlpha(parseFloat(e.target.value) || 0)} style={{ width: 70 }} /></label>
        <span style={{ fontSize: 12, color: "#666" }}>عتبة WI: جزئي ≥ {thresholdLow} | مخدوم ≥ {thresholdHigh}</span>
      </div>

      <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginBottom: 8, alignItems: "center" }}>
        <span style={{ fontSize: 12, fontWeight: "bold" }}>المنطقة:</span>
        {effectiveZones.map(z => (
          <button key={z.id} onClick={() => setZoneFilter(z.id === "__all__" ? null : z.id)}
            style={{ padding: "2px 8px", fontSize: 12, background: currentZone.id === z.id ? "#1565c0" : "#eee", color: currentZone.id === z.id ? "white" : "black", border: "none", borderRadius: 4, cursor: "pointer" }}>
            📍 {z.name}
          </button>
        ))}
      </div>

      <div style={{ marginBottom: 8 }}>
        <label>تدفق المضخة: <input type="number" value={qIn} onChange={e => setQIn(parseFloat(e.target.value) || 0)} style={{ width: 70 }} /> م³/س</label>
        <label style={{ marginRight: 10 }}>عدد ساعات الضخ: <input type="number" value={pumpHours} onChange={e => setPumpHours(parseFloat(e.target.value) || 0)} style={{ width: 60 }} /> ساعة</label>
        <span style={{ fontSize: 12, color: "#1565c0", fontWeight: "bold", marginRight: 10 }}>Q الكلية = {zoneQ.toFixed(0)} م³</span>
        <span style={{ fontSize: 12, color: "#666" }}>الاستهلاك الكلي: {totalDemand.toFixed(1)} م³ | التغطية: {(coverage * 100).toFixed(1)}%</span>
      </div>

      <div style={{ maxHeight: 400, overflowY: "auto", marginBottom: 8 }}>
        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 12 }}>
          <thead style={{ position: "sticky", top: 0, background: "#e3f2fd" }}>
            <tr>
              <th>#</th><th>الاسم</th><th title="ΔH = ارتفاع المشترك - أدنى ارتفاع في الحي">ΔH (م)</th><th>الاستهلاك</th><th>qmax</th><th>الحصة</th><th>WI</th><th>نظرياً</th><th>فعلياً</th>
            </tr>
          </thead>
          <tbody>
            {results.map((r, i) => {
              const ss = statusStyle(r.status);
              return (
              <tr key={r.subId} style={{ background: r.deviation === -1 ? "#ffebee" : r.actualStatus === "وصلت" ? "#e8f5e9" : i % 2 === 0 ? "#fafafa" : "white" }}>
                <td>{r.subId}</td>
                <td>{subscribers.find(s => s.id === r.subId)?.name || ""}</td>
                <td>{r.deltaH.toFixed(1)}</td>
                <td><input type="number" value={r.demand} onChange={e => onUpdateSubscriber(r.subId, "demand", parseFloat(e.target.value) || 0)} style={{ width: 55, fontSize: 11 }} /></td>
                <td><input type="number" value={subscribers.find(s => s.id === r.subId)?.qmax ?? 0} onChange={e => onUpdateSubscriber(r.subId, "qmax", parseFloat(e.target.value) || 0)} style={{ width: 55, fontSize: 11 }} /></td>
                <td>{r.supply.toFixed(2)}</td>
                <td>{r.wi.toFixed(4)}</td>
                <td style={{ color: ss.color, fontWeight: "bold" }}>
                  {r.status === "served" ? "✅ مخدوم" : r.status === "partial" ? "⚠️ جزئي" : "❌ غير مخدوم"}
                </td>
                <td>
                  <select value={r.actualStatus || "لم يُعرف"} onChange={e => { const v = e.target.value as ActualStatus; setActualStatus(prev => ({ ...prev, [r.subId]: v })); }} style={{ fontSize: 11 }}>
                    <option value="لم يُعرف">—</option><option value="وصلت">وصلت</option><option value="ضغط ضعيف">ضغط ضعيف</option><option value="لم تصل">لم تصل</option>
                  </select>
                </td>
              </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Bar chart: X = ΔH, Y = الاستهلاك + الحصة */}
      {results.length > 0 && (
        <div style={{ marginBottom: 8 }}>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={results.map(r => ({ ΔH: r.deltaH.toFixed(0), الاستهلاك: r.demand, الحصة: r.supply }))}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="ΔH" fontSize={10} label={{ value: "ΔH (م)", position: "insideBottom", offset: -5, style: { fontSize: 10 } }} />
              <YAxis fontSize={11} label={{ value: "م³", angle: -90, position: "insideLeft", offset: 0, style: { fontSize: 10 } }} />
              <Tooltip contentStyle={{ fontSize: 11 }} />
              <Legend wrapperStyle={{ fontSize: 11 }} />
              <Bar dataKey="الاستهلاك" fill="#78909c" name="الاستهلاك (م³)" />
              <Bar dataKey="الحصة" fill="#1565c0" name="الحصة (م³)" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      )}

      <div style={{ display: "flex", gap: 16, flexWrap: "wrap", fontSize: 13 }}>
        <div style={{ background: "#e3f2fd", padding: "8px 12px", borderRadius: 6 }}>
          ✅ مخدوم: {served.length}<br />⚠️ جزئي: {partial.length}<br />❌ غير مخدوم: {notServed.length}
        </div>
        <div style={{ background: "#e8f5e9", padding: "8px 12px", borderRadius: 6 }}>
          وصلت فعلياً: {actualServed.length}<br />نسبة الفاقد: {lossPercent.toFixed(1)}%
        </div>
        <div style={{ background: "#fff3e0", padding: "8px 12px", borderRadius: 6 }}>
          مناطق اشتباه: {suspicionZones.length}<br />أقصى ΔH مخدوم: {maxServedH.toFixed(1)} م
        </div>
        {suspicionZones.length > 0 && (
          <div style={{ background: "#ffebee", padding: "8px 12px", borderRadius: 6, maxWidth: 220 }}>
            ⚠️ آخر اشتباه: مشترك {suspicionZones[suspicionZones.length - 1].start} ← {suspicionZones[suspicionZones.length - 1].end}<br />
            <span style={{ fontSize: 11 }}>احتمال فاقد أو سرقة في هذه المنطقة</span>
          </div>
        )}
      </div>

      {zones.length > 0 && (
        <div style={{ marginTop: 10, background: "#fafafa", padding: 8, borderRadius: 6, fontSize: 12 }}>
          <strong>📊 تقارير الأحياء</strong>
          {effectiveZones.filter(z => z.id !== "__all__").map(z => {
            const zSubs = subscribers.filter(s => z.subscriberIds.includes(s.id));
            const zDemand = zSubs.reduce((s, sub) => s + sub.demand, 0);
            const zQCalc = qIn * pumpHours;
            const zCov = zDemand > 0 ? Math.min(zQCalc / zDemand, 1) : 0;
            return (
              <div key={z.id} style={{ marginTop: 4, padding: "4px 8px", background: "white", border: "1px solid #ddd", borderRadius: 4 }}>
                <b>{z.name}</b> — الاستهلاك: {zDemand.toFixed(0)} م³ | Q: {zQCalc.toFixed(0)} م³ | التغطية: {(zCov * 100).toFixed(0)}% 
                | المشتركين: {zSubs.length}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
export default AnalysisPanel;