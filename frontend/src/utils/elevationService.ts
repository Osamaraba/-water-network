export interface ElevationResult {
  lat: number;
  lon: number;
  elevation: number;
}

export async function fetchElevations(points: { lat: number; lon: number }[]): Promise<ElevationResult[]> {
  const chunkSize = 50;
  const results: ElevationResult[] = [];
  for (let i = 0; i < points.length; i += chunkSize) {
    const chunk = points.slice(i, i + chunkSize);
    const locations = chunk.map(p => ({ latitude: p.lat, longitude: p.lon }));
    try {
      const res = await fetch("https://api.open-elevation.com/api/v1/lookup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ locations }),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      for (const r of data.results) {
        results.push({ lat: r.latitude, lon: r.longitude, elevation: r.elevation });
      }
    } catch {
      for (const p of chunk) results.push({ lat: p.lat, lon: p.lon, elevation: 350 });
    }
  }
  return results;
}
