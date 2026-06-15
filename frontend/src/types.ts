export interface Subscriber {
  id: number;
  name: string;
  elevation: number;
  deltaH?: number;
  demand: number;
  qmax: number;
  received: number;
  completed: boolean;
  arrival_time: number | null;
  completion_time: number | null;
  fill_percent: number;
  lat: number | null;
  lon: number | null;
  connection_elevation?: number | null;
}

export interface AnalysisResult {
  subId: number;
  deltaH: number;
  demand: number;
  supply: number;
  wi: number;
  status: "served" | "partial" | "not-served";
  actualStatus?: "وصلت" | "ضغط ضعيف" | "لم تصل" | "لم يُعرف";
  deviation: number;
}

export interface SimulationConfig {
  q_in: number;
  area: number;
  dt: number;
  sim_hours: number;
  k: number;
  source_head: number;
  speed: number;
}

export interface SimulationStep {
  time: number;
  water_level: number;
  active_subscriber_id: number | null;
  subscribers: Subscriber[];
  progress: number;
}

export interface Connection {
  subId: number;
  pipeId: string;
  lat: number;
  lon: number;
  elevation?: number;
}

export interface NamedZone {
  id: string;
  name: string;
  subscriberIds: number[];
  latlngs: [number, number][];
}
