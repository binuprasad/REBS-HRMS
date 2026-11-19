# REBS HRMS Mock API Server

A standalone mock HTTP server with scenario simulation, UUID-based idempotency handling, and a web control panel for testing the **REBS HRMS** Flutter application.

---

## 🚀 How to Run

### Option 1: Standard Node.js (Zero external dependencies needed!)
```bash
node mock_server/server.js
```
Or:
```bash
npm --prefix mock_server start
```

The server binds to `0.0.0.0:8080`.
- **Web Control Panel (Browser)**: [http://localhost:8080/](http://localhost:8080/)
- **Android Emulator Base URL**: `http://10.0.2.2:8080`
- **iOS Simulator / Desktop Base URL**: `http://localhost:8080`
- **Physical Device**: Use your local LAN IP (e.g. `http://192.168.1.X:8080`) or [ngrok](https://ngrok.com) tunnel (`ngrok http 8080`).

---

## ⚡ 5 Repeatable Mock Scenarios

| Scenario | Code | Description |
|---|---|---|
| **Normal Success** | `normal` | Immediate 200 / 201 responses with valid payloads. |
| **Slow / Timeout** | `timeout` | Delays requests by 15,000ms (configurable) to trigger client Dio timeout and test idempotent sync retry. |
| **500 Server Error** | `server_error` | Simulates backend cluster crash returning HTTP 500. |
| **Duplicate Conflict** | `duplicate_conflict` | Simulates server rejecting duplicate attendance event (HTTP 409). |
| **Leave Validation Rejection** | `leave_validation_error` | Rejects leave submissions with HTTP 422 ("Policy restriction prohibits leave during sprint freeze period"). |

### Switching Scenarios
1. **Via Web Browser Dashboard**: Open `http://localhost:8080/` and click any scenario button.
2. **Via REST API**:
```bash
curl -X POST http://localhost:8080/api/scenarios \
  -H "Content-Type: application/json" \
  -d '{"scenario": "duplicate_conflict"}'
```
3. **Reset State**:
```bash
curl -X POST http://localhost:8080/api/reset
```

---

## 📡 Implemented Endpoints (Section 5)

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/employee/me` | Current employee profile & office geofence config |
| `GET` | `/attendance?month=YYYY-MM` | Attendance history (recent records, status, durations) |
| `POST` | `/attendance/events` | Submit check-in / check-out with **UUID Idempotency** & Geofence validation |
| `GET` | `/leave/balance` | Available casual and sick leave balances |
| `GET` | `/leave/requests` | List of employee's leave requests with status |
| `POST` | `/leave/requests` | Submit leave application with server-side validation & overlap check |

---

## 🔒 Idempotency & Retries
`POST /attendance/events` accepts a unique `clientEventId` (UUID v4) generated on the mobile client.
- When an event is first processed, it is recorded alongside its `clientEventId`.
- If network drops or times out and the client retries with the **same `clientEventId`**, the server detects the duplicate ID and immediately returns the previously committed record (`200 OK`) without creating duplicates or throwing 409 conflicts.
