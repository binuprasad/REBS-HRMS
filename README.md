# REBS HRMS — Offline-Capable Employee Workspace

A production-grade, offline-capable Flutter application built for the **REBS Business Automation Platform**. It enables employees to manage daily attendance with geofencing, track working duration with a live ticker, submit leave applications with validation, and view cached data while disconnected. Pending attendance actions are stored locally in Hive and synchronized reliably using an idempotent, FIFO sync engine.

---

## 🏗️ Architecture & Technology Stack

The project adheres to **Clean Architecture** principles, strictly decoupling business logic from presentation and infrastructure:

```
lib/
├── core/                       # Shared infrastructure & utilities
│   ├── constants/              # API endpoints & application constants
│   ├── di/                     # Dependency injection (GetIt service locator)
│   ├── error/                  # Domain failures & data exceptions
│   ├── location/               # GPS service & Developer Location Simulator
│   ├── network/                # Dio client, logging & error interceptors, NetworkInfo
│   ├── storage/                # HiveService, box declarations & persistence
│   ├── theme/                  # Material 3 design system & typography
│   ├── utils/                  # GeoUtils (Haversine distance) & DateTimeUtils
│   └── widgets/                # OfflineBanner, SyncIndicator, SimulatorDialog, SettingsModal
└── features/
    ├── dashboard/              # Employee summary, live ticker, balance preview, latest records
    │   ├── data/               # Remote & Local data sources, models, repository impl
    │   ├── domain/             # Composite DashboardData entity, repository contract, use cases
    │   └── presentation/       # DashboardBloc, states, events, responsive UI widgets
    ├── attendance/             # Attendance check-in/out, geofencing, offline queue
    │   ├── data/               # AttendanceRecordModel, AttendanceEventModel, local/remote DS
    │   ├── domain/             # AttendanceEvent, AttendanceRecord, SyncStatus, use cases
    │   └── presentation/       # AttendanceBloc, SyncBloc, history & action UI
    └── leave/                  # Leave quota, balance cards, application form & validation
        ├── data/               # LeaveBalanceModel, LeaveRequestModel, local/remote DS
        ├── domain/             # LeaveBalance, LeaveRequest, validation use cases
        └── presentation/       # LeaveBloc, history list, reactive ApplyLeaveScreen
```

### Technology Highlights
- **State Management**: `flutter_bloc` + `equatable` — Unidirectional data flow, explicit state transitions, zero business logic in widget build methods.
- **Networking**: `dio` — Configured with `AppLoggingInterceptor` and `ErrorInterceptor` for timeout mapping, connection recovery, and typed exception mapping.
- **Local Storage**: `hive_flutter` — Ultra-fast, crash-resilient NoSQL key-value storage for cached dashboards, attendance records, leave quotas, and offline event queues.
- **Location & Connectivity**: `geolocator` + `permission_handler` + `connectivity_plus` — Geofence calculation and reactive internet restoration triggers.
- **Event Identity**: `uuid` (UUID v4) — Guaranteed uniqueness for client-generated attendance event identity and server idempotency.

---

## ⚡ Mock API Server & Scenario Controller

The repository includes a standalone local mock server located in `/mock_server`. It implements all Section 5 endpoints and requires **zero npm packages** (runs out of the box with standard Node.js).

### Starting the Mock Server
```bash
node mock_server/server.js
# Or: npm --prefix mock_server start
```
The server runs on `http://0.0.0.0:8080`:
- **Web Control Panel (Browser)**: [http://localhost:8080/](http://localhost:8080/)
- **Android Emulator Endpoint**: `http://10.0.2.2:8080`
- **Physical Device / ngrok**: Paste your ngrok URL directly into the in-app Settings modal!

### 5 Repeatable Mock Scenarios
Reviewers can toggle scenarios with 1-click in the browser dashboard or via REST calls:

| Scenario | HTTP Behavior | App Handling |
|---|---|---|
| **Normal** | 200 / 201 Success | Immediate synchronization and state update. |
| **Timeout / Slow** | 15s Delay (Configurable) | Dio triggers timeout; event is saved locally as `Pending Sync` without losing user action. |
| **500 Server Error** | 500 Internal Server Error | Displays error banner; pending events remain queued in Hive for subsequent retries. |
| **Duplicate Conflict** | 409 Conflict | Server rejects duplicate submission; event is marked with `Rejected` badge with error reason. |
| **Leave Validation Rejection** | 422 Unprocessable Entity | Rejection message ("Policy restriction prohibits leave...") displayed on the form. |

---

## 🔄 Offline Storage & Idempotency Engineering

Handling offline operations and network timeouts without duplicating records is the core challenge.

### 1. Client-Generated UUID (`clientEventId`)
Every check-in and check-out event generated on the device receives a unique UUID v4 (`clientEventId`) upon tap.

### 2. Idempotent Retry Handling
- When a network timeout occurs, the client does not know whether the server accepted the request before the drop.
- During manual or automatic sync retry, the client transmits the **same `clientEventId`**.
- The server checks its in-memory database of processed client event IDs:
  - If already processed, it returns the existing record (`200 OK`) without creating duplicates.
  - If new, it records the event and returns `201 Created`.

### 3. Strict FIFO Chronological Queue
- Offline events are persisted in Hive `attendance_events_box` sorted by client creation timestamp.
- The sync engine processes pending events strictly in chronological order: **check-in is guaranteed to execute before check-out**.
- If a network drop occurs mid-queue, sync halts to prevent out-of-order execution.

### 4. Reactive Auto-Sync & Manual Sync
- Subscribes to `connectivity_plus`: when internet transitions from `offline -> online`, `SyncBloc` automatically dispatches `SyncNowRequested()`.
- A manual **"Sync Now"** pill in the AppBar provides instant status and manual sync trigger.

---

## 🛡️ Device-Side vs Server-Side Validation

The specification notes: *Device-side validation improves user experience; explain which checks a production server must repeat.*

| Check | Client-Side UX Purpose | Why Production Server MUST Repeat |
|---|---|---|
| **Office Geofence (200m)** | Instant feedback without network roundtrip if employee is remote. | GPS coordinates can be spoofed or mocked on rooted/jailbroken devices. Server must compute distance against authoritative office coordinates and IP/cell tower metadata. |
| **Single Check-In Per Day** | Prevents accidental double check-ins and UI confusion. | Race conditions (e.g. employee tapping check-in on two devices simultaneously, or syncing an offline device). Server must enforce unique constraint on `(employee_id, work_date)`. |
| **Check-Out After Check-In** | Guides user flow and avoids invalid state submissions. | Clock skew or malicious API requests could submit check-out without prior check-in. Server must verify check-in session existence. |
| **Leave Date Overlap** | Immediate form validation before submitting. | Concurrent leave requests or admin approval updates made on other platforms could create conflicting approvals. |
| **Leave Quota Availability** | Prevents user from requesting more days than available. | Available quota can change concurrently if another request was approved or adjusted by HR. Server must lock and deduct quota in an atomic transaction. |
| **Reason Minimum Length** | Client form validation feedback (>=10 chars). | Client-side validation can be bypassed by sending raw HTTP POST payloads. |

---

## 📍 Reviewer Location Simulator

Per Section 2, office coordinates (`12.971598, 77.594566`) and 200m perimeter are configurable:
- Tap the **Location Simulator Icon (📍)** in the AppBar or on the Today Attendance card.
- Select from:
  1. **🏢 At Office (Within 200m)**: Simulates exact office coordinates (0m distance).
  2. **🚗 Remote / Outside (1.5 km)**: Simulates location outside 200m geofence.
  3. **🎯 Custom Coordinates**: Enter any custom latitude and longitude.
  4. **📱 Real Device GPS**: Uses hardware GPS via `geolocator`.
- Also allows configuring custom office coordinates and radius directly in the dialog!

---

## ⚙️ In-App Server & ngrok Configuration

To test with a physical Android device or remote reviewer machine:
1. Tap the **Settings Icon (⚙️)** in the AppBar.
2. Paste your `ngrok` URL (e.g. `https://xxxx.ngrok-free.app`) or choose presets (`10.0.2.2:8080` for Android emulator, `localhost:8080`).
3. Tap **"Test Connection"** to verify latency.
4. Tap **"Save & Apply"**: Persisted in Hive `settings_box` and automatically updates Dio Base URL without restarting the app.

---

## 🧪 Automated Tests (Section 7)

The project includes automated tests covering all requirements from Section 7:

```bash
# Run all automated tests
flutter test
```

### Tests Covered:
1. **Check-out without check-in is rejected**: Verified via `test/features/attendance/attendance_rules_test.dart`.
2. **Repeated submission or retry does not create duplicate attendance**: Verified via `test/features/attendance/attendance_rules_test.dart`.
3. **Pending attendance survives persistence and synchronizes in FIFO order**: Verified via `test/features/attendance/attendance_rules_test.dart`.
4. **Overlapping leave dates are rejected**: Verified via `test/features/leave/leave_validation_test.dart`.
5. **Widget Tests**: Verified via `test/widget_test.dart` covering `OfflineBanner`, loading, and retry callbacks.

---

## 📦 Building & Running

### Prerequisites
- Flutter SDK 3.44+
- Node.js 18+ (for mock server)

### Running the App
```bash
# 1. Start mock server
node mock_server/server.js

# 2. Run Flutter app
flutter run
```

### Installable Debug APK
The debug APK is generated at:
```bash
build/app/outputs/flutter-apk/app-debug.apk
```
