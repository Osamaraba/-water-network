import React, { useState, useCallback, useEffect } from "react";
import { useMap, Polyline, Polygon, CircleMarker, Popup } from "react-leaflet";
import L from "leaflet";

export interface PipeLine {
  id: string;
  latlngs: [number, number][];
}

export interface PolygonZone {
  id: string;
  latlngs: [number, number][];
}

interface DrawingToolProps {
  onPipesChange: (pipes: PipeLine[]) => void;
  pipes: PipeLine[];
  onPolygonComplete?: (polygon: PolygonZone) => void;
}

function pointInPolygon(point: [number, number], polygon: [number, number][]): boolean {
  let inside = false;
  const n = polygon.length;
  for (let i = 0, j = n - 1; i < n; j = i++) {
    const xi = polygon[i][1], yi = polygon[i][0];
    const xj = polygon[j][1], yj = polygon[j][0];
    if ((yi > point[0]) !== (yj > point[0]) && point[1] < ((xj - xi) * (point[0] - yi)) / (yj - yi) + xi) {
      inside = !inside;
    }
  }
  return inside;
}

export function closestPointOnSegment(pt: [number, number], a: [number, number], b: [number, number]): [number, number] {
  const [px, py] = pt;
  let [ax, ay] = a;
  let [bx, by] = b;
  const dx = bx - ax, dy = by - ay;
  const len2 = dx * dx + dy * dy;
  if (len2 === 0) return a;
  let t = ((px - ax) * dx + (py - ay) * dy) / len2;
  t = Math.max(0, Math.min(1, t));
  return [ax + t * dx, ay + t * dy];
}

export function findNearestPipePoint(sub: { lat: number; lon: number }, pipes: PipeLine[]): { pipeId: string; lat: number; lon: number } | null {
  let bestDist = Infinity;
  let best: { pipeId: string; lat: number; lon: number } | null = null;
  for (const pipe of pipes) {
    for (let i = 0; i < pipe.latlngs.length; i++) {
      const pt = pipe.latlngs[i];
      const d = (pt[0] - sub.lat) ** 2 + (pt[1] - sub.lon) ** 2;
      if (d < bestDist) { bestDist = d; best = { pipeId: pipe.id, lat: pt[0], lon: pt[1] }; }
    }
    for (let i = 0; i < pipe.latlngs.length - 1; i++) {
      const pt = closestPointOnSegment([sub.lat, sub.lon], pipe.latlngs[i], pipe.latlngs[i + 1]);
      const d = (pt[0] - sub.lat) ** 2 + (pt[1] - sub.lon) ** 2;
      if (d < bestDist) { bestDist = d; best = { pipeId: pipe.id, lat: pt[0], lon: pt[1] }; }
    }
  }
  return best;
}

const DrawingTool: React.FC<DrawingToolProps> = ({ onPipesChange, pipes, onPolygonComplete }) => {
  const map = useMap();
  const [mode, setMode] = useState<"idle" | "pipe" | "polygon">("idle");
  const [points, setPoints] = useState<[number, number][]>([]);
  const [tempLine, setTempLine] = useState<[number, number][]>([]);
  const [zones, setZones] = useState<PolygonZone[]>([]);

  useEffect(() => {
    if (mode === "idle") return;
    const cursor = "crosshair";
    map.getContainer().style.cursor = cursor;

    const handleClick = (e: L.LeafletMouseEvent) => {
      const pt: [number, number] = [e.latlng.lat, e.latlng.lng];
      setPoints(prev => [...prev, pt]);
    };

    const handleDblClick = () => {
      setPoints(prev => {
        if (prev.length >= 3 && mode === "polygon") {
          const zone: PolygonZone = { id: `zone_${Date.now()}`, latlngs: [...prev] };
          setZones(z => [...z, zone]);
          onPolygonComplete?.(zone);
        } else if (prev.length >= 2 && mode === "pipe") {
          const newPipe: PipeLine = { id: `pipe_${Date.now()}`, latlngs: [...prev] };
          onPipesChange([...pipes, newPipe]);
        }
        return [];
      });
      setMode("idle");
    };

    map.on("click", handleClick);
    map.on("dblclick", handleDblClick);

    return () => {
      map.getContainer().style.cursor = "";
      map.off("click", handleClick);
      map.off("dblclick", handleDblClick);
    };
  }, [mode, map, pipes, onPipesChange, onPolygonComplete]);

  useEffect(() => { setTempLine(points); }, [points]);

  const finishDrawing = useCallback(() => {
    if (mode === "pipe" && points.length >= 2) {
      const newPipe: PipeLine = { id: `pipe_${Date.now()}`, latlngs: [...points] };
      onPipesChange([...pipes, newPipe]);
    } else if (mode === "polygon" && points.length >= 3) {
      const zone: PolygonZone = { id: `zone_${Date.now()}`, latlngs: [...points] };
      setZones(z => [...z, zone]);
      onPolygonComplete?.(zone);
    }
    setPoints([]);
    setMode("idle");
  }, [mode, points, pipes, onPipesChange, onPolygonComplete]);

  const clearAllLines = () => onPipesChange([]);
  const removeZone = (id: string) => setZones(z => z.filter(z => z.id !== id));
  const clearAllZones = () => setZones([]);

  return (
    <div style={{ position: "absolute", top: 10, left: 10, zIndex: 1000, display: "flex", gap: 4, flexDirection: "column" }}>
      <button onClick={() => { setMode(mode === "pipe" ? "idle" : "pipe"); setPoints([]); }}
        style={{ padding: "6px 12px", background: mode === "pipe" ? "#d32f2f" : "#1565c0", color: "white", border: "none", borderRadius: 4, cursor: "pointer", fontSize: 13 }}>
        {mode === "pipe" ? "❌ إلغاء" : "✏️ خط مياه"}
      </button>
      <button onClick={() => { setMode(mode === "polygon" ? "idle" : "polygon"); setPoints([]); }}
        style={{ padding: "6px 12px", background: mode === "polygon" ? "#d32f2f" : "#e65100", color: "white", border: "none", borderRadius: 4, cursor: "pointer", fontSize: 13 }}>
        {mode === "polygon" ? "❌ إلغاء" : "🔲 تحديد حي"}
      </button>
      {mode === "polygon" && points.length >= 3 && (
        <button onClick={finishDrawing} style={{ padding: "4px 8px", background: "#28a745", color: "white", border: "none", borderRadius: 4, cursor: "pointer" }}>
          ✅ إنهاء الحي
        </button>
      )}
      {mode === "pipe" && points.length >= 2 && (
        <button onClick={finishDrawing} style={{ padding: "4px 8px", background: "#28a745", color: "white", border: "none", borderRadius: 4, cursor: "pointer" }}>
          ✅ إنهاء الخط
        </button>
      )}
      {mode !== "idle" && (
        <span style={{ background: "white", padding: "4px 8px", borderRadius: 4, fontSize: 12 }}>
          {points.length} نقاط (انقر مزدوجاً للإنهاء)
        </span>
      )}
      {pipes.length > 0 && mode === "idle" && (
        <button onClick={clearAllLines} style={{ padding: "4px 8px", background: "#6c757d", color: "white", border: "none", borderRadius: 4, cursor: "pointer", fontSize: 12 }}>
          🗑️ حذف الخطوط ({pipes.length})
        </button>
      )}
      {zones.length > 0 && mode === "idle" && (
        <button onClick={clearAllZones} style={{ padding: "4px 8px", background: "#6c757d", color: "white", border: "none", borderRadius: 4, cursor: "pointer", fontSize: 12 }}>
          🗑️ حذف الأحياء ({zones.length})
        </button>
      )}

      {/* Temp line while drawing */}
      {tempLine.length > 0 && mode === "pipe" && (
        <Polyline positions={tempLine} pathOptions={{ color: "#ff6f00", weight: 3, opacity: 0.8, dashArray: "6 3" }} />
      )}

      {/* Saved pipes */}
      {pipes.map(pipe => (
        <Polyline key={pipe.id} positions={pipe.latlngs} pathOptions={{ color: "#1565c0", weight: 3, opacity: 0.8 }}>
          <Popup>
            <div style={{ textAlign: "center" }}>
              <strong>خط مياه</strong><br />
              الطول: {pipe.latlngs.length} نقاط<br />
              <button onClick={() => onPipesChange(pipes.filter(p => p.id !== pipe.id))} style={{ color: "red", border: "none", background: "none", cursor: "pointer" }}>🗑️ حذف</button>
            </div>
          </Popup>
        </Polyline>
      ))}

      {/* Saved polygon zones */}
      {zones.map(zone => (
        <Polygon key={zone.id} positions={zone.latlngs} pathOptions={{ color: "#e65100", weight: 2, fillColor: "#e65100", fillOpacity: 0.12 }}>
          <Popup>
            <div style={{ textAlign: "center" }}>
              <strong>الحي</strong><br />
              {zone.latlngs.length} نقاط<br />
              <button onClick={() => removeZone(zone.id)} style={{ color: "red", border: "none", background: "none", cursor: "pointer" }}>🗑️ حذف</button>
            </div>
          </Popup>
        </Polygon>
      ))}

      {/* Vertices while drawing */}
      {mode !== "idle" && points.map((pt, i) => (
        <CircleMarker key={i} center={pt} radius={4}
          pathOptions={{ color: "#ff6f00", fillColor: "#ff6f00", fillOpacity: 1, weight: 2 }}>
          <Popup>نقطة {i + 1}</Popup>
        </CircleMarker>
      ))}
    </div>
  );
};

export { pointInPolygon };
export default DrawingTool;
