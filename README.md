# REBS HRMS — Offline-Capable Employee Workspace

A production-ready, offline-first Flutter application built for the **REBS Business Automation Platform** (HRMS Module). The app enables employees to track attendance with 200m geofencing, view live elapsed working duration via a real-time ticker, submit and manage leave applications, and view cached data while disconnected. Offline attendance events are preserved in local storage and synchronized with idempotent FIFO guarantees upon network restoration.

Target Platform: **Android / iOS** | Clean Architecture | Strict Null-Safety

---

## 📑 Table of Contents
1. [Architecture & Technology Stack](#1-architecture--technology-stack)
2. [Package Choices & Justifications](#2-package-choices--justifications)
3. [Setup & Running Instructions (Local & ngrok)](#3-setup--running-instructions-local--ngrok)
4. [Offline Storage, Event Identity & Idempotency Engine](#4-offline-storage-event-identity--idempotency-engine)
5. [Device-Side vs. Server-Side Validation Matrix](#5-device-side-vs-server-side-validation-matrix)
6. [Reviewer Tools (Location Simulator & Scenario Switcher)](#6-reviewer-tools-location-simulator--scenario-switcher)
7. [Automated Test Suite (Section 7 Verification)](#7-automated-test-suite-section-7-verification)
8. [Demonstration Guide (3–5 Minute Video Walkthrough)](#8-demonstration-guide-35-minute-video-walkthrough)
9. [Trade-offs, Unfinished Features & AI Disclosure](#9-trade-offs-unfinished-features--ai-disclosure)

---

## 1. Architecture & Technology Stack

The project strictly follows **Clean Architecture** with separation into Domain, Data, and Presentation layers:

```
lib/
├── core/                       # Shared infrastructure & utilities
│   ├── constants/              # API endpoints, company timezone, geofence radius (200m)
│   ├── di/                     # Dependency injection (GetIt service locator)
│   ├── error/                  # Domain Failures & Data Exceptions
│   ├── location/               # GPS LocationService & Reviewer Simulator
│   ├── network/                # Dio client, logging & error interceptors, NetworkInfo
│   ├── storage/                # HiveService, box declarations & persistence
│   ├── theme/                  # Material 3 styling, color tokens & typography
│   ├── utils/                  # GeoUtils (Haversine formula) & DateTimeUtils
│   └── widgets/                # OfflineBanner, SyncIndicator, SimulatorDialog, SettingsModal
└── features/
    ├── dashboard/              # Employee profile, live ticker, leave preview, latest 5 records
    │   ├── data/               # Remote & Local data sources, EmployeeModel, repo impl
    │   ├── domain/             # DashboardData entity, repository contract, use cases
    │   └── presentation/       # DashboardBloc, states, events, responsive UI widgets
    ├── attendance/             # Attendance check-in/out, geofencing, offline sync queue
    │   ├── data/               # AttendanceRecordModel, AttendanceEventModel, local/remote DS
    │   ├── domain/             # AttendanceEvent, AttendanceRecord, SyncStatus, use cases
    │   └── presentation/       # AttendanceBloc, SyncBloc, history list & action buttons
    └── leave/                  # Leave balance, requests list, apply leave form & validations
        ├── data/               # LeaveBalanceModel, LeaveRequestModel, local/remote DS
        ├── domain/             # LeaveBalance, LeaveRequest, validation use cases
        └── presentation/       # LeaveBloc, history list, reactive ApplyLeaveScreen
```

---

## 2. Package Choices & Justifications

| Package | Choice Justification |
|---|---|
| `flutter_bloc` + `equatable` | **State Management**: Provides predictable, unidirectional data flow with explicit event-driven state transitions. Decouples business rules from widgets (zero logic inside `build()` methods). `equatable` prevents redundant UI rebuilds by comparing props value equality. |
| `dio` | **Networking**: Powerful HTTP client supporting request/response interceptors. Implements `AppLoggingInterceptor` for traffic monitoring and `ErrorInterceptor` to seamlessly map connection errors, timeouts (408), conflicts (409), and validation errors (422) into typed domain failures. |
| `hive_flutter` | **Local Storage**: Lightning-fast, crash-resilient NoSQL key-value database written in pure Dart. Ideal for mobile offline caching (dashboard, attendance history, leave quotas) and persistent queue management without SQLite migration overhead. |
| `geolocator` + `permission_handler` | **Location Services**: High-accuracy GPS position retrieval and distance calculation (`Geolocator.distanceBetween`). Gracefully handles disabled services, denied permissions, and permanently denied states with direct links to device app settings. |
| `connectivity_plus` | **Connectivity Detection**: Emits reactive stream of network interface changes (`wifi`, `cellular`, `none`) to trigger automatic synchronization when internet connectivity returns. |
| `uuid` | **Event Identity**: Generates collision-proof UUID v4 strings on the client for `clientEventId`, guaranteeing server-side idempotency across retries and timeouts. |

---

## 3. Setup & Running Instructions (Local & ngrok)

### Prerequisites
- Flutter SDK `^3.44.0` (Dart `^3.12.0`)
- Node.js `^18.0.0` (for mock server)
- Android Studio / Android SDK Platform 35+

### Step 1: Start the Standalone Mock Server
The mock server in `/mock_server` is written in standard Node.js (**zero npm install required**):
```bash
# From the project root
node mock_server/server.js
# Or: npm --prefix mock_server start
```
The server will start on `http://0.0.0.0:8080`:
- **Web Control Panel (Browser)**: [http://localhost:8080/](http://localhost:8080/)
- **Android Emulator Address**: `http://10.0.2.2:8080`

### Step 2: Running with ngrok (For Physical Devices or Remote Review)
If running on a physical Android device or remote machine:
```bash
# Expose the local mock server to the internet
ngrok http 8080
```
Copy your forwarding URL (e.g. `https://xxxx.ngrok-free.app`).

### Step 3: Run the Flutter App
```bash
flutter run
```

### Step 4: Configure the Server URL in the App
1. Tap the **Settings Icon (⚙️)** in the top right AppBar.
2. Paste your `ngrok` URL or select the `10.0.2.2:8080 (Emulator)` preset.
3. Tap **"Test Connection"** to verify latency.
4. Tap **"Save & Apply"**: The new Base URL is saved in Hive (`settings_box`) and immediately updates the Dio network client without restarting the app!

### Installable Debug APK Deliverable
The compiled debug APK is located at:
```bash
build/app/outputs/flutter-apk/app-debug.apk
```
To re-build at any time:
```bash
flutter build apk --debug
```

---

## 4. Offline Storage, Event Identity & Idempotency Engine

Handling offline operations and network timeouts without duplicating records is the main engineering challenge:

```
[User Taps Check-In]
        │
        ▼
Generate Client UUID (v4)
        │
        ▼
Save to Hive Box as "Pending Sync" (Crash Resilient)
        │
        ▼
   Online? ─── No ───► Stay in Hive Queue (Pending Sync) ──► Show Amber Badge
        │
       Yes
        ▼
POST /attendance/events (with clientEventId)
        │
   ┌────┴──────────────────────────┬────────────────────────┐
   ▼                               ▼                        ▼
200/201 OK                   409 Conflict               Timeout / Drop
   │                               │                        │
Mark "Synced" in Hive         Mark "Rejected" in Hive    Leave "Pending Sync"
   │                               │                        │
Show Green Badge              Show Red Badge + Reason    Auto-Retry on Reconnect
```

### 1. Client-Generated UUID (`clientEventId`)
Every check-in and check-out event receives a unique UUID v4 upon generation. This ID represents the immutable identity of the physical user action.

### 2. Idempotency Strategy for Timeouts & Retries
- When a client sends an event, the server might process the database transaction, but a network interruption or timeout occurs before the client receives the response.
- When the client reconnects or syncs, it re-transmits the **same `clientEventId`**.
- The server checks its in-memory database of processed IDs:
  - **Duplicate detected**: Server returns the existing record (`200 OK`) with the committed event data without creating a duplicate.
  - **New event**: Server commits the event and returns `201 Created`.

### 3. Strict FIFO Chronological Ordering
- All pending events in Hive are ordered chronologically by client generation timestamp.
- The sync engine processes pending events sequentially: **check-in is guaranteed to execute before check-out**.
- If a network failure occurs midway through the queue, synchronization immediately halts to prevent out-of-order execution.

### 4. Automatic & Manual Synchronization
- **Automatic**: `SyncBloc` listens to `connectivity_plus`. When internet transitions from `disconnected -> connected`, auto-sync triggers immediately.
- **Manual**: Reviewers can tap the AppBar sync pill at any time to trigger **"Sync Now"**.

---

## 5. Device-Side vs. Server-Side Validation Matrix

*Important: Device-side validation improves user experience; explain which checks a production server must repeat.*

| Validation Rule | Client-Side UX Purpose | Why Production Server MUST Repeat |
|---|---|---|
| **Office Geofence (200m)** | Provides instantaneous user feedback without waiting for network roundtrip when outside the office. | GPS coordinates can be spoofed or mocked on rooted/jailbroken devices or modified via reverse-engineered API calls. Production server must compute distance against authoritative office coordinates and corroborate with IP/cell tower metadata. |
| **Single Check-In Per Day** | Prevents duplicate taps and visual confusion in the UI. | Race conditions (e.g. an employee tapping check-in on two devices simultaneously or syncing an offline device). Production server must enforce database unique constraints on `(employee_id, work_date, event_type)`. |
| **Check-Out After Check-In** | Guides user flow and disables invalid check-out actions. | Clock skew or malicious requests could submit check-out without prior check-in. Production server must verify the existence of an open check-in session for that working date. |
| **Leave Date Overlap Check** | Form validation feedback before submitting. | Concurrent leave requests or admin approval updates made on other platforms could create conflicting approvals. Production server must execute atomic overlap queries with database table locks. |
| **Leave Quota Limit Check** | Prevents user from applying for more days than available. | Available quota can change concurrently if another request was approved or adjusted by HR administration. Production server must lock and deduct quota in an atomic database transaction. |
| **Reason Min Length (>=10 chars)** | Client-side form guidance. | Raw HTTP requests can bypass client UI form validators. Production server must validate non-whitespace character length before database insertion. |

---

## 6. Reviewer Tools (Location Simulator & Scenario Switcher)

### Built-in Reviewer Location Simulator (AppBar 📍 Icon)
No external fake GPS apps or developer options are required:
- **🏢 At Office (Within 200m)**: Emits office coordinates (`12.971598, 77.594566`, 0m away, inside 200m geofence).
- **🚗 Remote / Outside (1.5 km)**: Emits coordinates ~1500m away (outside 200m geofence).
- **🎯 Custom Coordinates**: Allows entering custom latitude and longitude values.
- **📱 Real Device GPS**: Reads hardware GPS via `geolocator`.
- **Configurable Office Coordinates**: Reviewers can change the office location and geofence radius directly from this dialog.

### Standalone Mock Scenario Switcher (Browser Dashboard)
Open `http://localhost:8080/` in any browser to toggle scenarios:
1. **Normal (200 / 201)**: Standard successful responses.
2. **Slow / Timeout**: Delays responses by 15,000ms (configurable) to test Dio client timeouts and subsequent idempotent retries.
3. **500 Server Error**: Simulates server crashes.
4. **409 Duplicate Conflict**: Simulates server rejecting duplicate attendance events.
5. **422 Leave Validation Rejection**: Simulates server-side leave policy rejection (*"Policy restriction prohibits leave during sprint freeze period"*).

Or toggle programmatically:
```bash
curl -X POST http://localhost:8080/api/scenarios -H "Content-Type: application/json" -d '{"scenario": "duplicate_conflict"}'
curl -X POST http://localhost:8080/api/reset
```

---

## 7. Automated Test Suite (Section 7 Verification)

Run the full automated test suite:
```bash
flutter test
```

### Test Coverage Breakdown:
1. **Unit Test 1: Check-out without check-in is rejected**
   - File: `test/features/attendance/attendance_rules_test.dart`
   - Verifies that `repository.checkOut()` throws a `ValidationFailure` when no active check-in exists for today.
2. **Unit Test 2: Repeated submission or retry does not create duplicate attendance**
   - File: `test/features/attendance/attendance_rules_test.dart`
   - Verifies that duplicate check-ins on the same day throw `ConflictFailure`, and retries with the same `clientEventId` return the existing record without duplicating.
3. **Unit Test 3: Pending attendance survives persistence across repository re-initialization and syncs in strict FIFO order**
   - File: `test/features/attendance/attendance_rules_test.dart`
   - Simulates offline check-in and check-out saved to persistent storage, destroys the repository, re-instantiates a brand new repository instance (simulating app restart), and verifies that pending events are read from storage and synchronized in strict chronological order (`CHECK_IN` before `CHECK_OUT`).
4. **Unit Test 4: Overlapping leave dates against existing Pending/Approved requests are rejected**
   - File: `test/features/leave/leave_validation_test.dart`
   - Verifies that `SubmitLeaveRequestUseCase` rejects dates overlapping existing requests, past dates, backwards date ranges, reasons under 10 chars, and requests exceeding quota.
5. **Widget Tests: Dashboard / Attendance screen showing Pending Sync indicator and offline state**
   - File: `test/widget_test.dart`
   - Tests `DashboardScreen` rendering the `OfflineBanner` when viewing cached data, verifies `SyncIndicatorButton` displaying `"2 offline"` with cloud off icon, and tests syncing spinner state.

---

## 8. Demonstration Guide (3–5 Minute Video Walkthrough)

To record the 3–5 minute demonstration video matching Section 8 requirements:

1. **Dashboard Loading**:
   - Launch the app. Show employee profile (Alex Morgan, ID: EMP-001, Mobile Engineering), Today's Attendance status (Not Checked In), Leave balance (Casual: 8d, Sick: 7d), and latest 5 attendance records.
2. **Online Check-In**:
   - Ensure simulator mode is set to "At Office (Within 200m)". Tap **"CHECK IN NOW"**.
   - Show status updating to "Checked In" with emerald Synced badge, check-in timestamp, and the live elapsed working duration ticker actively counting up every second.
3. **Offline Attendance Action**:
   - Turn off Wi-Fi/Mobile data (or set mock server scenario to `timeout`).
   - Tap **"CHECK OUT NOW"**. Show check-out recorded locally with status updated to "Checked Out", and the AppBar sync pill badged with **"1 offline"** / **"1 to sync"**.
4. **App Restart with Pending Action Preserved**:
   - Force close the Flutter application and re-launch it.
   - Show that today's checked-out state and the pending sync queue (`1 to sync`) survive persistence completely from Hive.
5. **Synchronization After Reconnecting**:
   - Restore internet connectivity (or reset mock server to `normal`).
   - Tap the sync pill or show automatic sync trigger. The pending event synchronizes, and status updates to "Synced" with a green confirmation toast.
6. **Leave Validation and Submission**:
   - Navigate to the **Leaves** tab. Tap **"Apply Leave"**.
   - Demonstrate client validations: try submitting with < 10 characters in reason or overlapping dates (shows inline error).
   - Switch mock server scenario to `leave_validation_error` and submit a valid form: show the server's 422 error banner displayed on the form.
   - Switch back to `normal` and submit: show successful creation (`LR-1003`) and updated quota balances.

---

## 9. Trade-offs, Unfinished Features & AI Disclosure

### Engineering Trade-offs
- **In-Memory Mock State vs. SQLite for Mock Server**: The mock server uses in-memory JavaScript structures with instant reset endpoints. This ensures zero external npm dependencies, running immediately on any reviewer machine without database setup.
- **Manual Hive Adapters vs. build_runner**: Storing serialized JSON maps in Hive boxes avoids fragile `build_runner` code generation steps and version drift, providing 100% crash-free schema flexibility.
- **Single Working Session per Day**: Assumes one check-in/check-out session per calendar day without overnight shifts, as permitted by the specification.

### Out of Scope / Unfinished Features
- User authentication & multi-employee login (explicitly excluded in Section 1 of specification).
- Background location tracking while the application is terminated (explicitly excluded in Section 3).

### AI Tooling Disclosure
- Antigravity AI assistant was used for code scaffolding, Clean Architecture boilerplate generation, and test suite setup in accordance with the assignment guidelines. All architectural decisions, state management patterns, and idempotency guarantees have been thoroughly verified and tested.
