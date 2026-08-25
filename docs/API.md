# API Documentation
## Yarmouk Water Platform API

### Base URL
```
Production:  https://api.yarmouk-water.jo/v1
Development: http://localhost:8000
```

### Authentication
All endpoints require Bearer token except `/auth/login` and `/auth/refresh`.

```
Authorization: Bearer <access_token>
```

---

## Authentication

### POST /auth/login
```json
{
  "username": "EMP001",
  "password": "password",
  "device_uuid": "abc123...",
  "platform": "android",
  "manufacturer": "Samsung",
  "model": "Galaxy S24",
  "os_version": "14",
  "app_version": "1.0.0"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbG...",
    "refresh_token": "eyJhbG...",
    "token_type": "bearer",
    "expires_in": 1800,
    "employee": {
      "employee_id": 1,
      "employee_number": "EMP001",
      "full_name": "أحمد محمد",
      "role_id": 6,
      "department": "الصيانة",
      "branch": "عجلون"
    }
  }
}
```

### POST /auth/refresh
```json
{"refresh_token": "eyJhbG..."}
```

---

## Attendance

### POST /attendance/check-in
```json
{
  "latitude": 32.3325,
  "longitude": 35.7523,
  "accuracy": 8.5,
  "device_time": "2026-08-21T08:00:00Z",
  "gps_time": "2026-08-21T08:00:00Z",
  "device_uuid": "abc123...",
  "is_mock_location": false,
  "client_transaction_id": "TXN-..."
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "log_id": 1,
    "session_id": "uuid",
    "transaction_id": "TXN-...",
    "check_in_time": "2026-08-21T08:00:00Z",
    "trust_score": 95,
    "trust_status": "valid",
    "in_geofence": true,
    "server_time": "2026-08-21T08:00:01Z"
  }
}
```

### POST /attendance/check-out
```json
{
  "latitude": 32.3325,
  "longitude": 35.7523,
  "accuracy": 10.2,
  "device_time": "2026-08-21T16:00:00Z",
  "gps_time": "2026-08-21T16:00:00Z"
}
```

---

## GPS

### POST /gps/session/start
```json
{
  "latitude": 32.3325,
  "longitude": 35.7523,
  "device_uuid": "abc123..."
}
```

### POST /gps/telemetry
```json
{
  "session_id": "uuid",
  "points": [
    {
      "latitude": 32.3325,
      "longitude": 35.7523,
      "accuracy": 8.5,
      "altitude": 850.0,
      "speed": 12.5,
      "heading": 90.0,
      "battery_level": 78,
      "network_type": "4G",
      "recorded_at": "2026-08-21T08:00:00Z"
    }
  ]
}
```

### GET /gps/employees/live
**Response:**
```json
{
  "success": true,
  "data": [
    {
      "employee_id": 1,
      "full_name": "أحمد محمد",
      "latitude": 32.3325,
      "longitude": 35.7523,
      "speed": 12.5,
      "battery_level": 78,
      "last_update": "2026-08-21T08:00:00Z"
    }
  ]
}
```

---

## Incidents

### POST /incidents
```json
{
  "incident_type": "صيانة",
  "priority": "critical",
  "title": "كسر في خط مياه رئيسي",
  "description": "وصف الحادث...",
  "latitude": 32.3325,
  "longitude": 35.7523,
  "location_address": "شارع الملك حسين"
}
```

### POST /incidents/{id}/accept
No body required.

### POST /incidents/{id}/arrive
```json
{
  "latitude": 32.3325,
  "longitude": 35.7523
}
```

---

## WebSocket

### Connection
```
WS /ws/live
```

### Events

**Subscribe:**
```json
{"type": "subscribe", "channels": ["employee.location", "incident.updated"]}
```

**Employee Location:**
```json
{
  "type": "employee.location",
  "employee_id": 1,
  "data": {
    "latitude": 32.3325,
    "longitude": 35.7523,
    "speed": 12.5,
    "timestamp": "2026-08-21T08:00:00Z"
  }
}
```

**Security Alert:**
```json
{
  "type": "security.alert",
  "data": {
    "event_type": "MOCK_LOCATION",
    "severity": "critical",
    "employee_id": 1,
    "description": "Mock location detected"
  }
}
```
