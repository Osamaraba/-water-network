import { Subscriber } from "../types";
import { PipeLine } from "../components/DrawingTool";
import { NamedZone } from "../types";

function kmlCoord(lat: number, lon: number, alt = 0): string {
  return `${lon},${lat},${alt}`;
}

function escapeXml(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function subscribersToKml(subs: Subscriber[]): string {
  return subs.filter(s => s.lat && s.lon).map(s => `
    <Placemark>
      <name>${escapeXml(s.name)}</name>
      <description>الارتفاع: ${s.elevation} م
الطلب: ${s.demand} م³
المستلم: ${s.received.toFixed(2)} م³
الإنجاز: ${s.fill_percent.toFixed(1)}%</description>
      <Point>
        <coordinates>${kmlCoord(s.lat!, s.lon!, s.elevation)}</coordinates>
      </Point>
      <ExtendedData>
        <Data name="elevation"><value>${s.elevation}</value></Data>
        <Data name="demand"><value>${s.demand}</value></Data>
        <Data name="received"><value>${s.received.toFixed(2)}</value></Data>
        <Data name="fill_percent"><value>${s.fill_percent.toFixed(1)}</value></Data>
      </ExtendedData>
    </Placemark>`).join("");
}

function pipesToKml(pipes: PipeLine[]): string {
  return pipes.map(p => `
    <Placemark>
      <name>خط مياه</name>
      <LineString>
        <coordinates>${p.latlngs.map(c => kmlCoord(c[0], c[1])).join(" ")}</coordinates>
      </LineString>
    </Placemark>`).join("");
}

function zonesToKml(zones: NamedZone[]): string {
  return zones.map(z => `
    <Placemark>
      <name>${escapeXml(z.name)}</name>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>${z.latlngs.map(c => kmlCoord(c[0], c[1])).join(" ")}</coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>`).join("");
}

export function exportKml(subs: Subscriber[], pipes: PipeLine[], zones: NamedZone[], filename = "water_network.kml"): void {
  const kml = `<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>شبكة توزيع المياه</name>
    ${subscribersToKml(subs)}
    ${pipesToKml(pipes)}
    ${zonesToKml(zones)}
  </Document>
</kml>`;

  const blob = new Blob([kml], { type: "application/vnd.google-earth.kml+xml" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
