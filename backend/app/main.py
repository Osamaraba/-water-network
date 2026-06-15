from fastapi import FastAPI, UploadFile, File, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import pandas as pd
import asyncio
import json
from typing import Dict
from .models import SubscriberState, SimulationConfig
from .excel_parser import parse_excel_to_subscribers
from .simulation import WaterSimulation

app = FastAPI(title="Water Distribution Simulator")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])
active_simulations: Dict[str, Dict] = {}

@app.post("/upload-excel/")
async def upload_excel(file: UploadFile = File(...)):
    try:
        df = pd.read_excel(file.file)
        subscribers_input = parse_excel_to_subscribers(df)
        subscribers_state = []
        for idx, inp in enumerate(subscribers_input):
            sub = SubscriberState(
                id=idx+1,
                name=inp.name,
                elevation=inp.elevation,
                demand=inp.demand,
                qmax=inp.qmax,
                lat=inp.lat,
                lon=inp.lon,
            )
            subscribers_state.append(sub)
        return {"subscribers": [s.model_dump() for s in subscribers_state], "count": len(subscribers_state)}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error parsing Excel: {str(e)}")

@app.websocket("/ws/{simulation_id}")
async def websocket_endpoint(websocket: WebSocket, simulation_id: str):
    await websocket.accept()
    try:
        data = await websocket.receive_text()
        payload = json.loads(data)
        config = SimulationConfig(**payload.get("config", {}))
        subscribers_data = payload.get("subscribers", [])
        subscribers = [SubscriberState(**s) for s in subscribers_data]
        sim = WaterSimulation(subscribers, config)
        total_steps = int(config.sim_hours / config.dt)
        step_idx = 0
        while step_idx < total_steps and not all(s.completed for s in sim.subs):
            step_data = sim.step()
            step_idx += 1
            await websocket.send_json(step_data.model_dump())
            delay = max(0.01, (config.dt * 3600) / config.speed)
            try:
                receive_task = asyncio.create_task(websocket.receive_text())
                sleep_task = asyncio.create_task(asyncio.sleep(delay))
                done, pending = await asyncio.wait(
                    [receive_task, sleep_task],
                    return_when=asyncio.FIRST_COMPLETED,
                    timeout=delay + 5
                )
                for task in done:
                    if task == receive_task:
                        msg = json.loads(task.result())
                        cmd = msg.get("command", "")
                        if cmd == "stop_pump":
                            sim.pump_on = False
                        elif cmd == "start_pump":
                            sim.pump_on = True
                        elif cmd == "set_qin":
                            sim.set_qin(float(msg.get("value", sim.config.q_in)))
                for task in pending:
                    task.cancel()
            except asyncio.TimeoutError:
                pass
        await websocket.send_json({"status": "finished"})
    except WebSocketDisconnect:
        print(f"Client {simulation_id} disconnected")
    except Exception as e:
        await websocket.send_json({"error": str(e)})
