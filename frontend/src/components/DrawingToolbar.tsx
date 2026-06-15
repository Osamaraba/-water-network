import React, { useEffect, useRef, useState } from "react";
import { useMap } from "react-leaflet";
import L from "leaflet";
import "leaflet-draw";
import "leaflet/dist/leaflet.css";
import "leaflet-draw/dist/leaflet.draw.css";

interface PipeLine {
  id: string;
  latlngs: [number, number][];
}

interface DrawingToolbarProps {
  onPipesChange: (pipes: PipeLine[]) => void;
  pipes: PipeLine[];
}

const DrawingToolbar: React.FC<DrawingToolbarProps> = ({ onPipesChange, pipes }) => {
  const map = useMap();
  const drawnItemsRef = useRef<L.FeatureGroup>(new L.FeatureGroup());
  const [enabled, setEnabled] = useState(false);

  useEffect(() => {
    const group = drawnItemsRef.current;
    map.addLayer(group);

    const drawControl = new (L.Control as any).Draw({
      edit: { featureGroup: group },
      draw: {
        polygon: false,
        rectangle: false,
        circle: false,
        circlemarker: false,
        marker: false,
        polyline: { shapeOptions: { color: "#1565c0", weight: 3 } },
      },
    });

    const handleCreated = (e: any) => {
      const layer = e.layer;
      group.addLayer(layer);
      if (layer instanceof L.Polyline) {
        const latlngs = layer.getLatLngs();
        const coords = (latlngs as L.LatLng[]).map((ll: L.LatLng) => [ll.lat, ll.lng] as [number, number]);
        const newPipe: PipeLine = { id: `pipe_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`, latlngs: coords };
        onPipesChange([...pipes, newPipe]);
      }
    };

    const handleEdited = () => {
      const updated: PipeLine[] = [];
      group.eachLayer((layer: any) => {
        if (layer instanceof L.Polyline) {
          const latlngs = layer.getLatLngs();
          const coords = (latlngs as L.LatLng[]).map((ll: L.LatLng) => [ll.lat, ll.lng] as [number, number]);
          const existing = pipes.find(p => {
            if (p.latlngs.length !== coords.length) return false;
            return p.latlngs.every((c, i) => c[0] === coords[i][0] && c[1] === coords[i][1]);
          });
          updated.push(existing || { id: `pipe_${Date.now()}`, latlngs: coords });
        }
      });
      onPipesChange(updated);
    };

    const handleDeleted = (e: any) => {
      const deletedLayers = e.layers;
      const remaining = pipes.filter(p => {
        let found = false;
        deletedLayers.eachLayer((dl: any) => {
          if (dl instanceof L.Polyline) {
            const latlngs = dl.getLatLngs();
            const coords = (latlngs as L.LatLng[]).map((ll: L.LatLng) => [ll.lat, ll.lng] as [number, number]);
            if (p.latlngs.length === coords.length && p.latlngs.every((c, i) => c[0] === coords[i][0] && c[1] === coords[i][1])) {
              found = true;
            }
          }
        });
        return !found;
      });
      onPipesChange(remaining);
    };

    map.on(L.Draw.Event.CREATED, handleCreated);
    map.on(L.Draw.Event.EDITED, handleEdited);
    map.on(L.Draw.Event.DELETED, handleDeleted);

    return () => {
      map.removeLayer(group);
      map.off(L.Draw.Event.CREATED, handleCreated);
      map.off(L.Draw.Event.EDITED, handleEdited);
      map.off(L.Draw.Event.DELETED, handleDeleted);
    };
  }, [map, pipes, onPipesChange]);

  return null;
};

export default DrawingToolbar;
export type { PipeLine };
