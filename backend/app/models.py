from pydantic import BaseModel
from typing import Optional, List

class SubscriberInput(BaseModel):
    name: str
    elevation: float
    demand: float
    qmax: float
    lat: Optional[float] = None
    lon: Optional[float] = None
    connection_elevation: Optional[float] = None

class SubscriberState(BaseModel):
    id: int
    name: str
    elevation: float
    demand: float
    qmax: float
    received: float = 0.0
    completed: bool = False
    arrival_time: Optional[float] = None
    completion_time: Optional[float] = None
    fill_percent: float = 0.0
    lat: Optional[float] = None
    lon: Optional[float] = None
    connection_elevation: Optional[float] = None

class SimulationConfig(BaseModel):
    q_in: float = 10.0
    area: float = 50.0
    dt: float = 0.05
    sim_hours: float = 72.0
    k: float = 1.2
    source_head: float = 450.0
    speed: float = 3600.0

class SimulationStepData(BaseModel):
    time: float
    water_level: float
    active_subscriber_id: Optional[int]
    subscribers: List[SubscriberState]
    progress: float
