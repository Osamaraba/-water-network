import React, { useState } from "react";
import { Subscriber, NamedZone } from "../types";

const STATUS_FILTERS = ["الكل", "مكتمل", "يُخدم الآن", "انتظار", "لم يبدأ"] as const;

type SortKey = "elevation" | "demand" | "received" | "id" | "deltaH";

interface StatusTableProps {
  subscribers: Subscriber[];
  activeId: number | null;
  activeZoneId: string | null;
  onZoneFilterChange: (id: string | null) => void;
  zones: NamedZone[];
  onUpdateSubscriber?: (id: number, field: string, value: number) => void;
}

const StatusTable: React.FC<StatusTableProps> = ({ subscribers, activeId, activeZoneId, onZoneFilterChange, zones, onUpdateSubscriber }) => {
  const [statusFilter, setStatusFilter] = useState<string>("الكل");
  const [sortKey, setSortKey] = useState<SortKey>("elevation");
  const [sortAsc, setSortAsc] = useState(true);
  const [search, setSearch] = useState("");

  const handleSort = (key: SortKey) => {
    if (sortKey === key) setSortAsc(!sortAsc);
    else { setSortKey(key); setSortAsc(true); }
  };

  const activeZone = zones.find(z => z.id === activeZoneId);
  const zoneIdSet = activeZone ? new Set(activeZone.subscriberIds) : null;

  const filteredSubs = [...subscribers]
    .filter(s => {
      if (statusFilter !== "الكل") {
        const st = s.completed ? "مكتمل" : activeId === s.id ? "يُخدم الآن" : s.arrival_time ? "انتظار" : "لم يبدأ";
        if (st !== statusFilter) return false;
      }
      if (zoneIdSet && !zoneIdSet.has(s.id)) return false;
      if (search && !s.name.includes(search)) return false;
      return true;
    });

  const minElev = filteredSubs.length > 0 ? Math.min(...filteredSubs.map(s => s.elevation)) : 0;

  const sorted = filteredSubs
    .sort((a, b) => {
      const mul = sortAsc ? 1 : -1;
      return (a[sortKey] - b[sortKey]) * mul || a.id - b.id;
    });

  const arrow = (key: SortKey) => sortKey === key ? (sortAsc ? " ▲" : " ▼") : "";

  return (
    <div>
      <div style={{ display: "flex", gap: 6, marginBottom: 6, flexWrap: "wrap", alignItems: "center" }}>
        <input
          type="text" placeholder="🔍 بحث بالاسم..." value={search}
          onChange={e => setSearch(e.target.value)}
          style={{ padding: "4px 8px", borderRadius: 4, border: "1px solid #ccc", width: 180 }}
        />
        {zones.map(z => {
          const isActive = activeZoneId === z.id;
          return (
            <button key={z.id} onClick={() => onZoneFilterChange(isActive ? null : z.id)} style={{
              padding: "2px 10px", backgroundColor: isActive ? "#e65100" : "#eee",
              color: isActive ? "white" : "black",
              border: "none", borderRadius: 4, cursor: "pointer"
            }}>
              📍 {z.name} ({z.subscriberIds.length})
            </button>
          );
        })}
      </div>
      <div style={{ display: "flex", gap: 6, marginBottom: 6, flexWrap: "wrap" }}>
        {STATUS_FILTERS.map(f => (
          <button key={f} onClick={() => setStatusFilter(f)}
            style={{ padding: "2px 10px", backgroundColor: statusFilter === f ? "#007bff" : "#eee", color: statusFilter === f ? "white" : "black", border: "none", borderRadius: 4, cursor: "pointer" }}>
            {f}
          </button>
        ))}
        {activeZoneId && (
          <button onClick={() => onZoneFilterChange(null)} style={{ padding: "2px 10px", backgroundColor: "#dc3545", color: "white", border: "none", borderRadius: 4, cursor: "pointer" }}>
            ❌ إلغاء فلتر الحي
          </button>
        )}
      </div>
      <div style={{ overflowX: "auto", maxHeight: "400px" }}>
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead style={{ position: "sticky", top: 0, backgroundColor: "#f0f0f0" }}>
            <tr>
              <th onClick={() => handleSort("id")} style={{ cursor: "pointer" }}>#{arrow("id")}</th>
              <th>الاسم</th>
              <th>الموقع (lat, lon)</th>
              <th onClick={() => handleSort("elevation")} style={{ cursor: "pointer" }}>الارتفاع{arrow("elevation")}</th>
              <th onClick={() => handleSort("deltaH")} style={{ cursor: "pointer" }}>ΔH{arrow("deltaH")}</th>
              <th>الطلب</th>
              <th>qmax (عوامة)</th>
              <th onClick={() => handleSort("received")} style={{ cursor: "pointer" }}>المستلم{arrow("received")}</th>
              <th>%</th>
              <th>زمن الوصول</th>
              <th>زمن الإكمال</th>
              <th>الحالة</th>
            </tr>
          </thead>
          <tbody>
            {sorted.map(sub => (
              <tr key={sub.id} style={{ backgroundColor: activeId === sub.id ? "#fff3cd" : "white" }}>
                <td>{sub.id}</td><td>{sub.name}</td><td>{sub.lat?.toFixed(4)}, {sub.lon?.toFixed(4)}</td><td>{sub.elevation}</td><td>{(sub.elevation - minElev).toFixed(1)}</td>
                <td><input type="number" value={sub.demand} onChange={e => onUpdateSubscriber?.(sub.id, "demand", parseFloat(e.target.value) || 0)} style={{ width: 60 }} /></td>
                <td><input type="number" value={sub.qmax} onChange={e => onUpdateSubscriber?.(sub.id, "qmax", parseFloat(e.target.value) || 0)} style={{ width: 60 }} /></td>
                <td>{sub.received.toFixed(3)}</td><td>{sub.fill_percent.toFixed(1)}%</td>
                <td>{sub.arrival_time !== null ? sub.arrival_time.toFixed(3) : "-"}</td>
                <td>{sub.completion_time !== null ? sub.completion_time.toFixed(3) : "-"}</td>
                <td>{sub.completed ? "مكتمل" : activeId === sub.id ? "يُخدم الآن" : sub.arrival_time ? "انتظار" : "لم يبدأ"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
export default StatusTable;
