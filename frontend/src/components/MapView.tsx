import React, { useEffect, useMemo, useState, useCallback } from "react";
import { MapContainer, TileLayer, CircleMarker, Popup, Tooltip, useMap, LayersControl, Polyline } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { Subscriber, Connection, NamedZone } from "../types";
import DrawingTool, { PipeLine, PolygonZone, pointInPolygon, findNearestPipePoint } from "./DrawingTool";
import { parseKmlFile } from "../utils/kmlParser";
import { fetchElevations } from "../utils/elevationService";
import SubscriberPanel from "./SubscriberPanel";
import { exportKml } from "../utils/kmlExporter";
import * as XLSX from "xlsx";

interface MapViewProps {
  subscribers: Subscriber[];
  activeId: number | null;
  pipes: PipeLine[];
  onPipesChange: (pipes: PipeLine[]) => void;
  onKmlSubscribers?: (subs: Subscriber[]) => void;
  onZonesChange?: (zones: NamedZone[]) => void;
  onElevationsUpdate?: (elevs: { id: number; elevation: number }[]) => void;
  initialZones?: NamedZone[];
  connections?: Connection[];
  onConnectionsChange?: (conns: Connection[]) => void;
}

const MapClickDeselect: React.FC<{ onDeselect: () => void; connectSubId: number | null; onConnectPlace: (lat: number, lon: number) => void }> = ({ onDeselect, connectSubId, onConnectPlace }) => {
  const map = useMap();
  const ref = React.useRef({ onDeselect, connectSubId, onConnectPlace });
  ref.current = { onDeselect, connectSubId, onConnectPlace };
  useEffect(() => {
    const handler = (e: L.LeafletMouseEvent) => {
      if (ref.current.connectSubId !== null) {
        ref.current.onConnectPlace(e.latlng.lat, e.latlng.lng);
      } else {
        ref.current.onDeselect();
      }
    };
    map.on("click", handler);
    return () => { map.off("click", handler); };
  }, [map]);
  return null;
};

const FitBounds: React.FC<{ subscribers: Subscriber[] }> = ({ subscribers }) => {
  const map = useMap();
  const fitted = React.useRef(false);
  useEffect(() => {
    if (fitted.current) return;
    const valid = subscribers.filter(s => s.lat !== null && s.lon !== null);
    if (valid.length) { map.fitBounds(L.latLngBounds(valid.map(s => [s.lat!, s.lon!]))); fitted.current = true; }
  }, [subscribers, map]);
  return null;
};



const ZoomCenter: React.FC = () => {
  const map = useMap();
  useEffect(() => {
    const el = map.zoomControl?.getContainer();
    if (!el) return;
    el.style.position = "absolute";
    el.style.bottom = "50px";
    el.style.left = "50%";
    el.style.transform = "translateX(-50%)";
  }, [map]);
  return null;
};



const getStatus = (sub: Subscriber, activeId: number | null): string => {
  if (sub.completed) return "مكتمل";
  if (sub.arrival_time !== null) return "يُخدم الآن";
  return "لم يبدأ";
};

const statusColor: Record<string, string> = {
  "مكتمل": "#1f77b4",
  "يُخدم الآن": "#e91e9e",
  "لم يبدأ": "#d32f2f",
};

function clusterSubs(subs: Subscriber[], k: number): { centroids: [number, number][]; assignments: number[] } {
  const valid = subs.filter(s => s.lat !== null && s.lon !== null);
  const n = valid.length;
  if (n === 0) return { centroids: [], assignments: [] };
  const coords = valid.map(s => [s.lat!, s.lon!] as [number, number]);
  const kk = Math.min(k, n);
  const centroids: [number, number][] = [];
  const assignments: number[] = new Array(n).fill(0);
  if (kk === 1) {
    const clat = coords.reduce((a, c) => a + c[0], 0) / n;
    const clon = coords.reduce((a, c) => a + c[1], 0) / n;
    return { centroids: [[clat, clon]], assignments: new Array(n).fill(0) };
  }
  for (let i = 0; i < kk; i++) centroids.push([24.65 + Math.random() * 0.15, 46.62 + Math.random() * 0.15]);
  for (let iter = 0; iter < 10; iter++) {
    for (let i = 0; i < n; i++) {
      let best = 0, bestDist = Infinity;
      for (let j = 0; j < kk; j++) {
        const d = (coords[i][0] - centroids[j][0]) ** 2 + (coords[i][1] - centroids[j][1]) ** 2;
        if (d < bestDist) { bestDist = d; best = j; }
      }
      assignments[i] = best;
    }
    const sums: [number, number, number][] = centroids.map(() => [0, 0, 0]);
    for (let i = 0; i < n; i++) {
      sums[assignments[i]][0] += coords[i][0];
      sums[assignments[i]][1] += coords[i][1];
      sums[assignments[i]][2] += 1;
    }
    for (let j = 0; j < kk; j++) {
      if (sums[j][2] > 0) centroids[j] = [sums[j][0] / sums[j][2], sums[j][1] / sums[j][2]];
    }
  }
  return { centroids, assignments };
}

const NetworkLines: React.FC<{ subscribers: Subscriber[] }> = ({ subscribers }) => {
  const valid = useMemo(() => subscribers.filter(s => s.lat !== null && s.lon !== null), [subscribers]);
  const { centroids, assignments } = useMemo(() => clusterSubs(valid, 5), [valid]);
  if (valid.length === 0 || centroids.length === 0) return null;

  const srcLat = valid.reduce((a, s) => a + s.lat!, 0) / valid.length;
  const srcLon = valid.reduce((a, s) => a + s.lon!, 0) / valid.length;
  const source: [number, number] = [srcLat, srcLon];

  return (
    <>
      {centroids.map((c, ci) => (
        <Polyline key={`src-${ci}`} positions={[source, c]}
          pathOptions={{ color: "#1565c0", weight: 3, opacity: 0.6, dashArray: "8 4" }} />
      ))}
      {valid.map((sub, i) => {
        const ci = assignments[i];
        if (ci >= centroids.length) return null;
        return (
          <Polyline key={`line-${sub.id}`} positions={[centroids[ci], [sub.lat!, sub.lon!]]}
            pathOptions={{ color: "#4fc3f7", weight: 1.5, opacity: 0.5 }} />
        );
      })}
      <CircleMarker center={source} radius={2}
        pathOptions={{ color: "#ffd600", fillColor: "#ffd600", fillOpacity: 0.8, weight: 3 }}>
        <Popup><strong>مصدر المياه</strong></Popup>
      </CircleMarker>
      {centroids.map((c, ci) => (
        <CircleMarker key={`v-${ci}`} center={c} radius={2}
          pathOptions={{ color: "#1565c0", fillColor: "#1565c0", fillOpacity: 0.5, weight: 2 }}>
          <Popup><strong>قرية {ci + 1}</strong></Popup>
        </CircleMarker>
      ))}
    </>
  );
};

const PanelContainer: React.FC<{
  subscribers: Subscriber[]; activeId: number | null; selectedIds: Set<number>; zones: NamedZone[]; connections: Connection[]; onHighlight: (id: number | null) => void;
}> = ({ subscribers, activeId, selectedIds, zones, connections, onHighlight }) => {
  const map = useMap();
  return (
    <SubscriberPanel
      subscribers={subscribers}
      activeId={activeId}
      selectedIds={selectedIds}
      zones={zones}
      connections={connections}
      onCenterSub={(id) => {
        const sub = subscribers.find(s => s.id === id);
        if (sub?.lat && sub?.lon) map.setView([sub.lat, sub.lon], 15, { animate: true });
        onHighlight(id);
      }}
    />
  );
};

const SubscriberMarker: React.FC<{
  sub: Subscriber; color: string; selected: boolean; status: string; activeId: number | null; highlighted: boolean; connElev?: number; connectMode?: boolean; onConnectSelect?: (id: number) => void;
}> = ({ sub, color, selected, status, highlighted, connElev, connectMode, onConnectSelect }) => {
  const map = useMap();
  const handleClick = useCallback((e: any) => {
    L.DomEvent.stopPropagation(e.originalEvent);
    if (connectMode && onConnectSelect) {
      onConnectSelect(sub.id);
    } else if (sub.lat && sub.lon) {
      map.setView([sub.lat, sub.lon], Math.max(map.getZoom(), 16), { animate: true });
    }
  }, [sub.lat, sub.lon, map, connectMode, onConnectSelect, sub.id]);
  const r = highlighted ? 6 : selected ? 3 : 2;
  return (
    <CircleMarker center={[sub.lat!, sub.lon!]} radius={r}
      eventHandlers={{ click: handleClick }}
      pathOptions={{
        color: highlighted ? "#ffd600" : color,
        fillColor: highlighted ? "#ffd600" : color,
        fillOpacity: highlighted ? 0.8 : selected ? 0.7 : 0.35,
        weight: highlighted ? 3 : selected ? 3 : 2,
        opacity: highlighted ? 1 : 0.8
      }}>
      <Tooltip direction="top" offset={[0, -4]}>
        <strong>{sub.name}</strong><br />
        الموقع: {sub.lat?.toFixed(4)}, {sub.lon?.toFixed(4)}<br />
        ارتفاع المشترك: {sub.elevation} م{connElev !== undefined ? ` | ارتفاع الربط: ${connElev} م` : ""}<br />
        الطلب: {sub.demand} m³ | المستلم: {sub.received.toFixed(2)} ({sub.fill_percent.toFixed(1)}%)<br />
        الحالة: {status}
        {selected && <><br /><span style={{ color: "#e65100" }}>📍 في الحي المحدد</span></>}
      </Tooltip>
    </CircleMarker>
  );
};

const MapView: React.FC<MapViewProps> = ({ subscribers, activeId, pipes, onPipesChange, onKmlSubscribers, onZonesChange, onElevationsUpdate, initialZones = [], connections = [], onConnectionsChange }) => {
  const defaultCenter: [number, number] = [24.713, 46.675];
  const [zones, setZones] = useState<PolygonZone[]>([]);
  const [namedZones, setNamedZones] = useState<NamedZone[]>(initialZones);
  const [highlightId, setHighlightId] = useState<number | null>(null);
  const kmlRef = React.useRef<HTMLInputElement>(null);

  const handleAutoConnect = useCallback(() => {
    const valid = subscribers.filter(s => s.lat !== null && s.lon !== null);
    const newConns: Connection[] = [];
    for (const sub of valid) {
      const nearest = findNearestPipePoint({ lat: sub.lat!, lon: sub.lon! }, pipes);
      if (nearest) newConns.push({ subId: sub.id, ...nearest, elevation: 0 });
    }
    onConnectionsChange?.(newConns);
  }, [subscribers, pipes, onConnectionsChange]);

  const selectedIds = useMemo(() => {
    if (namedZones.length === 0) return new Set<number>();
    const ids = new Set<number>();
    for (const nz of namedZones) {
      for (const id of nz.subscriberIds) ids.add(id);
    }
    return ids;
  }, [namedZones]);

  const computeSubsInZone = (zone: PolygonZone): number[] => {
    const ids: number[] = [];
    for (const sub of subscribers) {
      if (sub.lat === null || sub.lon === null) continue;
      if (pointInPolygon([sub.lat, sub.lon], zone.latlngs)) {
        ids.push(sub.id);
      }
    }
    return ids;
  };

  const handlePolygonComplete = useCallback((zone: PolygonZone) => {
    const subIds = computeSubsInZone(zone);
    const name = window.prompt("اسم الحي:", `الحي ${namedZones.length + 1}`);
    if (!name) return;
    const nz: NamedZone = { id: zone.id, name, subscriberIds: subIds, latlngs: zone.latlngs };
    const updated = [...namedZones, nz];
    setNamedZones(updated);
    setZones(prev => [...prev, zone]);
    onZonesChange?.(updated);
  }, [namedZones, onZonesChange]);

  const [importing, setImporting] = useState(false);
  const [fetchingElevations, setFetchingElevations] = useState(false);
  const [connectSubId, setConnectSubId] = useState<number | null>(null);

  const handleConnectSelect = useCallback((id: number) => {
    if (connectSubId !== null && connectSubId !== -1 && connectSubId !== id) { setConnectSubId(id); return; }
    if (connectSubId === id) { setConnectSubId(null); return; }
    const hasConn = connections.some(c => c.subId === id);
    if (hasConn) {
      onConnectionsChange?.(connections.filter(c => c.subId !== id));
      setConnectSubId(-1);
    } else {
      setConnectSubId(id);
    }
  }, [connectSubId, connections, onConnectionsChange]);

  const handleConnectPlace = useCallback((lat: number, lon: number) => {
    if (connectSubId === null) return;
    try {
      const nearest = findNearestPipePoint({ lat, lon }, pipes);
      if (nearest) {
        const existing = connections.find(c => c.subId === connectSubId);
        if (existing) {
          onConnectionsChange?.(connections.map(c => c.subId === connectSubId ? { ...c, ...nearest, elevation: c.elevation ?? 0 } : c));
        } else {
          onConnectionsChange?.([...connections, { subId: connectSubId, ...nearest, elevation: 0 }]);
        }
      }
    } catch (err) { console.error("ربط:", err); }
    setConnectSubId(null);
  }, [connectSubId, pipes, connections, onConnectionsChange]);

  const handleFetchElevations = async () => {
    const pts = subscribers.filter(s => s.lat && s.lon && s.id);
    const connPts = connections.filter(c => {
      const sub = subscribers.find(s => s.id === c.subId);
      return sub?.lat && sub?.lon;
    });
    if (pts.length === 0 && connPts.length === 0) return;
    setFetchingElevations(true);
    try {
      const allPts = [...pts.map(s => ({ lat: s.lat!, lon: s.lon! })), ...connPts.map(c => ({ lat: c.lat, lon: c.lon }))];
      const results = await fetchElevations(allPts);
      const subUpdates = pts.map((s, i) => ({ id: s.id, elevation: results[i]?.elevation ?? s.elevation }));
      onElevationsUpdate?.(subUpdates);
      const connElevs = results.slice(pts.length);
      if (connElevs.length > 0) {
        const updatedConns = connections.map(c => {
          const idx = connPts.findIndex(cp => cp.subId === c.subId && cp.lat === c.lat && cp.lon === c.lon);
          return idx >= 0 ? { ...c, elevation: connElevs[idx]?.elevation ?? 0 } : c;
        });
        onConnectionsChange?.(updatedConns);
      }
      const total = subUpdates.length + connPts.length;
      alert(`تم تحديث ${total} ارتفاع (${subUpdates.length} مشترك + ${connPts.length} ربط)`);
    } catch {
      alert("فشل جلب الارتفاعات");
    } finally {
      setFetchingElevations(false);
    }
  };

  const handleKmlUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setImporting(true);
    try {
      const features = await parseKmlFile(file);
      const newPipes: PipeLine[] = [];
      const newSubs: Subscriber[] = [];
      for (const f of features) {
        if (f.type === "line") {
          newPipes.push({ id: `kml_${Date.now()}_${newPipes.length}`, latlngs: f.coordinates });
        } else if (f.type === "point" && onKmlSubscribers) {
          const maxId = subscribers.reduce((m, s) => Math.max(m, s.id), 0);
          newSubs.push({
            id: maxId + newSubs.length + 1,
            name: f.name,
            elevation: 350,
            demand: 500,
            qmax: 10,
            received: 0,
            completed: false,
            arrival_time: null,
            completion_time: null,
            fill_percent: 0,
            lat: f.coordinates[0][0],
            lon: f.coordinates[0][1],
          });
        }
      }
      onPipesChange([...pipes, ...newPipes]);
      if (newSubs.length > 0) onKmlSubscribers(newSubs);
      const msgs: string[] = [];
      if (newPipes.length > 0) msgs.push(`${newPipes.length} خط مياه`);
      if (newSubs.length > 0) msgs.push(`${newSubs.length} مشترك`);
      if (msgs.length > 0) alert(`تم استيراد: ${msgs.join(", ")} من KML`);
    } catch (err) {
      alert("خطأ في قراءة الملف: " + err);
    } finally {
      setImporting(false);
    }
    e.target.value = "";
  };

  const exportZoneToExcel = (zone: NamedZone) => {
    const rows = zone.subscriberIds.map(id => {
      const sub = subscribers.find(s => s.id === id);
      if (!sub) return null;
      const conn = connections.find(c => c.subId === id);
      const elev = Math.max(sub.elevation, conn?.elevation ?? 0);
      return { "الاسم": sub.name, "الارتفاع": elev, "الطلب": sub.demand, "معدل تصريف العوامه": sub.qmax, "خط العرض": sub.lat, "خط الطول": sub.lon };
    }).filter(Boolean);
    if (rows.length === 0) { alert("لا يوجد مشتركين في هذا الحي"); return; }
    const ws = XLSX.utils.json_to_sheet(rows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "مشتركين");
    XLSX.writeFile(wb, `${zone.name}.xlsx`);
  };

  return (
    <div>
      <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 4, flexWrap: "wrap" }}>
        <input ref={kmlRef} type="file" accept=".kml,.kmz" onChange={handleKmlUpload} style={{ display: "none" }} />
        <button onClick={() => kmlRef.current?.click()} style={{ padding: "4px 12px", background: "#4a148c", color: "white", border: "none", borderRadius: 4, cursor: "pointer" }}>
          📂 KML/KMZ (نقاط + شبكة)
        </button>
        {importing && <span style={{ fontSize: 12, color: "#4a148c" }}>جاري الاستيراد...</span>}
        {pipes.length > 0 && <span style={{ fontSize: 12, color: "#666" }}>{pipes.length} خط</span>}
        <button onClick={() => setConnectSubId(connectSubId !== null ? null : -1)} style={{ padding: "4px 12px", background: connectSubId !== null ? "#d32f2f" : "#1565c0", color: "white", border: "none", borderRadius: 4, cursor: "pointer", fontSize: 13 }}>
          {connectSubId !== null ? "❌ إلغاء ربط" : "✏️ ربط يدوي"}
        </button>
        {connectSubId !== null && connectSubId > 0 && <span style={{ fontSize: 12, color: "#ef6c00" }}>اختر موقع الربط على الخريطة</span>}
        <button onClick={handleAutoConnect} disabled={pipes.length === 0} style={{ padding: "4px 12px", background: "#00838f", color: "white", border: "none", borderRadius: 4, cursor: "pointer", fontSize: 13, opacity: pipes.length === 0 ? 0.5 : 1 }}>
          🔗 ربط تلقائي
        </button>

        <button onClick={handleFetchElevations} disabled={fetchingElevations} style={{ padding: "4px 12px", background: "#2e7d32", color: "white", border: "none", borderRadius: 4, cursor: "pointer", fontSize: 13 }}>
          🏔️ {fetchingElevations ? "جاري..." : "ارتفاعات"}
        </button>
        <button onClick={() => exportKml(subscribers, pipes, namedZones)} style={{ padding: "4px 12px", background: "#f57f17", color: "white", border: "none", borderRadius: 4, cursor: "pointer", fontSize: 13 }}>
          💾 حفظ KML
        </button>
      </div>
      <MapContainer center={defaultCenter} zoom={12} style={{ height: "500px", width: "100%" }}>
      <LayersControl position="topright">
        <LayersControl.BaseLayer checked name="شارع (واضح)">
          <TileLayer url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png" attribution="&copy; OpenStreetMap, &copy; CARTO" />
        </LayersControl.BaseLayer>
        <LayersControl.BaseLayer name="قمر صناعي">
          <TileLayer url="https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}" attribution="&copy; Esri" />
        </LayersControl.BaseLayer>
        <LayersControl.BaseLayer name="طبوغرافي + كنتور">
          <TileLayer url="https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}" attribution="&copy; Esri" />
        </LayersControl.BaseLayer>
        <LayersControl.BaseLayer name="خريطة خفيفة">
          <TileLayer url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png" attribution="&copy; OpenStreetMap, &copy; CARTO" />
        </LayersControl.BaseLayer>
      </LayersControl>
      <DrawingTool onPipesChange={onPipesChange} pipes={pipes} onPolygonComplete={handlePolygonComplete} />
      <FitBounds subscribers={subscribers} />
      <ZoomCenter />
      <MapClickDeselect onDeselect={() => setHighlightId(null)} connectSubId={connectSubId} onConnectPlace={handleConnectPlace} />
      <PanelContainer subscribers={subscribers} activeId={activeId} selectedIds={selectedIds} zones={namedZones} connections={connections} onHighlight={setHighlightId} />
      {namedZones.length > 0 && (
        <div style={{ position: "absolute", bottom: 10, right: 10, zIndex: 1000, background: "white", padding: "6px 12px", borderRadius: 6, fontSize: 13, boxShadow: "0 1px 4px rgba(0,0,0,0.2)" }}>
          {namedZones.map(z => <div key={z.id} style={{ display: "flex", alignItems: "center", gap: 6 }}>📍 {z.name}: {z.subscriberIds.length} مشترك <button onClick={() => exportZoneToExcel(z)} style={{ padding: "1px 6px", fontSize: 11, background: "#1565c0", color: "white", border: "none", borderRadius: 3, cursor: "pointer" }}>📥 Excel</button></div>)}
        </div>
      )}

      {connections.map(conn => {
        const sub = subscribers.find(s => s.id === conn.subId);
        if (!sub?.lat || !sub?.lon) return null;
        const isHigher = conn.elevation !== undefined && conn.elevation > sub.elevation;
        return <Polyline key={conn.subId} positions={[[sub.lat, sub.lon], [conn.lat, conn.lon]]} pathOptions={{ color: isHigher ? "#d32f2f" : "#00838f", weight: 1.5, dashArray: "4 4", opacity: 0.7 }} />;
      })}
      {subscribers.filter(s => s.lat && s.lon).map(sub => {
        const status = getStatus(sub, activeId);
        const color = statusColor[status];
        const selected = selectedIds.has(sub.id);
        const conn = connections.find(c => c.subId === sub.id);
        return (
          <SubscriberMarker key={sub.id} sub={sub} color={color} selected={selected} status={status} activeId={activeId} highlighted={highlightId === sub.id || connectSubId === sub.id} connElev={conn?.elevation} connectMode={connectSubId !== null} onConnectSelect={handleConnectSelect} />
        );
      })}
    </MapContainer>
    </div>
  );
};
export default MapView;