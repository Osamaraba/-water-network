import React, { useState } from "react";
import { SimulationConfig, Subscriber } from "../types";

const LABELS: Record<string, string> = {
  q_in: "التدفق (m³/h)", area: "المساحة (m²)", dt: "خطوة زمن (ساعة)",
  sim_hours: "مدة المحاكاة (ساعة)", k: "معامل الخشونة", source_head: "ضغط المصدر (م)", speed: "السرعة (ساعة/ثانية)"
};
const defaultConfig: SimulationConfig = { q_in: 200, area: 1000, dt: 0.5, sim_hours: 48, k: 5.0, source_head: 500, speed: 3600 };

const ControlPanel: React.FC<{
  onStart: (cfg: SimulationConfig, subs: Subscriber[]) => void;
  subscribers: Subscriber[];
  isRunning: boolean;
}> = ({ onStart, subscribers, isRunning }) => {
  const [config, setConfig] = useState(defaultConfig);
  const [show, setShow] = useState(false);
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) =>
    setConfig({ ...config, [e.target.name]: parseFloat(e.target.value) });
  const totalSteps = config.sim_hours / config.dt;
  return (
    <div style={{ padding: 10, border: "1px solid #ccc", borderRadius: 8, marginBottom: 10 }}>
      <div style={{ display: "flex", gap: 6, alignItems: "center", flexWrap: "wrap" }}>
        <button onClick={() => setShow(!show)}>⚙️ إعدادات</button>
        <button onClick={() => setConfig(c => ({ ...c, speed: 1 }))} style={{ padding: "3px 8px", background: "#1565c0", color: "white", border: "none", borderRadius: 4, cursor: "pointer", fontSize: 12, opacity: config.speed === 1 ? 0.5 : 1 }}>🕐 حقيقي</button>
        <button onClick={() => setConfig(c => ({ ...c, speed: Math.max(1, Math.round(120 * c.sim_hours)) }))} style={{ padding: "3px 8px", background: "#e65100", color: "white", border: "none", borderRadius: 4, cursor: "pointer", fontSize: 12 }}>⚡ سريع (~30 ث)</button>
        {show && (
          <span style={{ fontSize: 11, color: "#666" }}>
            {totalSteps} خطوة | {config.speed >= 3600 * config.dt ? "لحظي" : `~${Math.round(totalSteps * (config.dt * 3600) / config.speed)} ث`}
          </span>
        )}
      </div>
      {show && (
        <div style={{ marginTop: 10, display: "flex", gap: 15, flexWrap: "wrap" }}>
          {Object.entries(config).map(([k, v]) => (
            <label key={k} style={{ fontSize: 13 }}>
              {LABELS[k] || k}: <input name={k} type="number" value={v} onChange={handleChange} step="any" style={{ width: 70 }} />
            </label>
          ))}
        </div>
      )}
      <button
        onClick={() => onStart(config, subscribers)}
        disabled={isRunning || subscribers.length === 0}
        style={{
          marginTop: 10,
          padding: "5px 15px",
          backgroundColor: "#28a745",
          color: "white",
        }}
      >
        {isRunning ? "جاري..." : "▶ بدء المحاكاة"}
      </button>
    </div>
  );
};
export default ControlPanel;
