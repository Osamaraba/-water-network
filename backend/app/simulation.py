import math
from typing import List, Optional
from .models import SubscriberState, SimulationConfig, SimulationStepData

class WaterSimulation:
    def __init__(self, subscribers: List[SubscriberState], config: SimulationConfig):
        self.subs = subscribers
        self.config = config
        self.water_level = config.source_head
        self.time = 0.0
        self.history = []
        self.current_active_id: Optional[int] = None
        self.pump_on = True

    def set_qin(self, value: float):
        self.config.q_in = value

    def step(self) -> SimulationStepData:
        dt = self.config.dt
        q_in = self.config.q_in if self.pump_on else 0.0
        area = self.config.area
        k = self.config.k

        uncompleted = [sub for sub in self.subs if not sub.completed]
        uncompleted.sort(key=lambda x: x.elevation)

        available = q_in
        total_out = 0.0
        self.current_active_id = None
        first = True

        for sub in uncompleted:
            if available <= 0:
                break
            effective_elevation = max(sub.elevation, sub.connection_elevation if sub.connection_elevation is not None else -float('inf'))
            head = max(0.0, self.water_level - effective_elevation)
            q_pressure = k * math.sqrt(head) if head > 0 else 0.0
            remaining = max(0.0, sub.demand - sub.received)
            max_by_remaining = remaining / dt if dt > 0 else float('inf')

            if first:
                requested = min(q_pressure, max_by_remaining)
                first = False
            else:
                requested = min(q_pressure, sub.qmax, max_by_remaining)

            if requested <= 0:
                continue

            if sub.arrival_time is None:
                sub.arrival_time = self.time

            if self.current_active_id is None:
                self.current_active_id = sub.id
            allocated = min(requested, available)
            volume = allocated * dt
            sub.received += volume
            total_out += allocated
            available -= allocated
            sub.fill_percent = (sub.received / sub.demand) * 100.0 if sub.demand > 0 else 0.0
            if sub.received >= sub.demand * 0.999 and not sub.completed:
                sub.completed = True
                sub.completion_time = self.time + dt

        net_flow = q_in - total_out
        dh = (net_flow / area) * dt
        self.water_level += dh
        if self.water_level < 0:
            self.water_level = 0.0

        step_data = SimulationStepData(
            time=round(self.time, 3),
            water_level=round(self.water_level, 3),
            active_subscriber_id=self.current_active_id,
            subscribers=[sub.model_copy(deep=True) for sub in self.subs],
            progress=self.time / self.config.sim_hours if self.config.sim_hours > 0 else 0.0
        )
        self.history.append(step_data)
        self.time += dt
        return step_data

    def run_full(self, on_step_callback=None):
        total_steps = int(self.config.sim_hours / self.config.dt)
        for _ in range(total_steps):
            if all(sub.completed for sub in self.subs):
                break
            step_data = self.step()
            if on_step_callback:
                on_step_callback(step_data)
        return self.history, self.subs
