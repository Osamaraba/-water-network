import React, { useState } from "react";
import { Subscriber, Connection, NamedZone } from "../types";

interface SubscriberPanelProps {
  subscribers: Subscriber[];
  activeId: number | null;
  selectedIds: Set<number>;
  zones: NamedZone[];
  onCenterSub: (id: number) => void;
  connections?: Connection[];
}

const SubscriberPanel: React.FC<SubscriberPanelProps> = ({ subscribers, activeId, selectedIds, zones, onCenterSub, connections = [] }) => {
  const [zoneFilterLocal, setZoneFilterLocal] = useState<string | null>(null);

  const filtered = subscribers.filter(s => {
    if (zoneFilterLocal) {
      const zone = zones.find(z => z.id === zoneFilterLocal);
      return zone?.subscriberIds.includes(s.id);
    }
    return true;
  });

  return (
    <div style={{
      position: "absolute", top: 60, right: 0, zIndex: 999, width: 300,
      background: "white", borderRadius: "0 0 0 8px", boxShadow: "-2px 2px 8px rgba(0,0,0,0.2)",
      maxHeight: "70vh", display: "flex", flexDirection: "column"
    }}>
      <div style={{ padding: "8px 8px 0 8px", fontWeight: "bold", fontSize: 13, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <span>المشتركين ({filtered.length})</span>
      </div>
      {zones.length > 0 && (
        <div style={{ padding: "4px 8px" }}>
          <select onChange={e => setZoneFilterLocal(e.target.value || null)} value={zoneFilterLocal || ""}
            style={{ width: "100%", padding: 2, fontSize: 12 }}>
            <option value="">الكل</option>
            {zones.map(z => <option key={z.id} value={z.id}>{z.name} ({z.subscriberIds.length})</option>)}
          </select>
        </div>
      )}
      <div style={{ padding: "0 8px 8px 8px", overflowY: "auto", fontSize: 12 }}>
        {filtered.map(sub => (
          <div key={sub.id} onClick={() => onCenterSub(sub.id)} style={{
            display: "flex", justifyContent: "space-between", padding: "3px 6px", cursor: "pointer",
            borderRadius: 4, marginBottom: 2, background: activeId === sub.id ? "#fff3cd" : selectedIds.has(sub.id) ? "#fff8e1" : "#f5f5f5"
          }}>
            <span>{sub.name}</span>
            <span style={{ fontSize: 11 }}>
              {sub.elevation}m
              {(() => {
                const c = connections.find(x => x.subId === sub.id);
                if (!c) return null;
                const isHigher = c.elevation !== undefined && c.elevation > sub.elevation;
                return <span style={{ color: isHigher ? "#d32f2f" : "#666" }}> | {c.elevation ?? "?"}m</span>;
              })()}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default SubscriberPanel;
