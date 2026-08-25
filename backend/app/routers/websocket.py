from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import Dict, List
import json
import asyncio

router = APIRouter(prefix="/ws", tags=["WebSocket"])

# Connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        if client_id not in self.active_connections:
            self.active_connections[client_id] = []
        self.active_connections[client_id].append(websocket)

    def disconnect(self, websocket: WebSocket, client_id: str):
        if client_id in self.active_connections:
            self.active_connections[client_id].remove(websocket)
            if not self.active_connections[client_id]:
                del self.active_connections[client_id]

    async def broadcast(self, message: dict, client_id: str = None):
        if client_id and client_id in self.active_connections:
            for connection in self.active_connections[client_id]:
                try:
                    await connection.send_json(message)
                except:
                    pass
        else:
            for connections in self.active_connections.values():
                for connection in connections:
                    try:
                        await connection.send_json(message)
                    except:
                        pass

manager = ConnectionManager()

@router.websocket("/live")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket, "dashboard")
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)

            if message.get("type") == "subscribe":
                # Handle subscription to specific events
                pass
            elif message.get("type") == "ping":
                await websocket.send_json({"type": "pong"})

    except WebSocketDisconnect:
        manager.disconnect(websocket, "dashboard")
    except Exception:
        manager.disconnect(websocket, "dashboard")

async def broadcast_employee_location(employee_id: int, data: dict):
    await manager.broadcast({
        "type": "employee.location",
        "employee_id": employee_id,
        "data": data
    }, client_id="dashboard")

async def broadcast_incident_update(incident_id: int, data: dict):
    await manager.broadcast({
        "type": "incident.updated",
        "incident_id": incident_id,
        "data": data
    }, client_id="dashboard")

async def broadcast_security_alert(data: dict):
    await manager.broadcast({
        "type": "security.alert",
        "data": data
    }, client_id="dashboard")

async def broadcast_notification(data: dict):
    await manager.broadcast({
        "type": "notification",
        "data": data
    }, client_id="dashboard")
