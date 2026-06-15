import JSZip from "jszip";

export interface KmlFeature {
  type: "line" | "point";
  name: string;
  coordinates: [number, number][];
}

function parseKmlText(text: string): KmlFeature[] {
  const features: KmlFeature[] = [];
  const parser = new DOMParser();
  const xml = parser.parseFromString(text, "text/xml");
  if (xml.querySelector("parsererror")) return features;

  const placemarks = xml.getElementsByTagNameNS("*", "Placemark");
  for (let i = 0; i < placemarks.length; i++) {
    const pm = placemarks[i];
    const nameEl = pm.getElementsByTagNameNS("*", "name")[0];
    const name = nameEl?.textContent || `Feature ${i + 1}`;

    const coordsEl = pm.getElementsByTagNameNS("*", "LineString")[0]
      ?.getElementsByTagNameNS("*", "coordinates")[0];
    if (coordsEl?.textContent) {
      const coords = coordsEl.textContent.trim().split(/\s+/).map(part => {
        const [lon, lat] = part.split(",");
        return [parseFloat(lat), parseFloat(lon)] as [number, number];
      }).filter(c => !isNaN(c[0]) && !isNaN(c[1]));
      if (coords.length >= 2) {
        features.push({ type: "line", name, coordinates: coords });
      }
      continue;
    }

    const pointEl = pm.getElementsByTagNameNS("*", "Point")[0]
      ?.getElementsByTagNameNS("*", "coordinates")[0];
    if (pointEl?.textContent) {
      const parts = pointEl.textContent.trim().split(/\s+/)[0].split(",");
      const clat = parseFloat(parts[1]), clon = parseFloat(parts[0]);
      if (!isNaN(clat) && !isNaN(clon)) {
        features.push({ type: "point", name, coordinates: [[clat, clon]] });
      }
    }
  }
  return features;
}

export async function parseKmlFile(file: File): Promise<KmlFeature[]> {
  if (file.name.toLowerCase().endsWith(".kmz")) {
    const zip = await JSZip.loadAsync(file);
    const kmlFile = Object.keys(zip.files).find(f => f.endsWith(".kml"));
    if (!kmlFile) return [];
    const text = await zip.files[kmlFile].async("text");
    return parseKmlText(text);
  }
  const text = await file.text();
  return parseKmlText(text);
}
