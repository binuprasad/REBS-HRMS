/**
 * REBS HRMS Mock HTTP Server
 * 
 * Standalone mock server implementing Section 5 of the REBS HRMS Specification:
 * - GET /employee/me
 * - GET /attendance?month=YYYY-MM
 * - POST /attendance/events (with UUID idempotency & geofence validation)
 * - GET /leave/balance
 * - GET /leave/requests
 * - POST /leave/requests (with server-side validation & overlap check)
 * 
 * Scenarios supported:
 * 1. normal: Successful responses (200 / 201)
 * 2. timeout: Slow responses / timeouts (simulated delay, default 15s)
 * 3. server_error: 500 Internal Server Error
 * 4. duplicate_conflict: 409 Conflict on attendance events
 * 5. leave_validation_error: 422 Unprocessable Entity on leave submissions
 * 
 * Includes an interactive Web Control Panel at http://localhost:8080/
 */

const http = require('http');
const url = require('url');

const PORT = process.env.PORT || 8080;
const HOST = '0.0.0.0';

// Office Configuration
const OFFICE_CONFIG = {
  name: "REBS Headquarters",
  latitude: 12.971598,
  longitude: 77.594566,
  geofenceRadiusMeters: 200.0,
  companyTimezone: "Asia/Kolkata",
  workStartTime: "09:00",
  workEndTime: "18:00"
};

// Available Scenarios
const SCENARIOS = {
  NORMAL: 'normal',
  TIMEOUT: 'timeout',
  SERVER_ERROR: 'server_error',
  DUPLICATE_CONFLICT: 'duplicate_conflict',
  LEAVE_VALIDATION_ERROR: 'leave_validation_error',
};

let currentScenario = SCENARIOS.NORMAL;
let timeoutDelayMs = 15000; // 15 seconds to trigger Dio connection/receive timeout
const requestLogs = [];

// Helper: Haversine distance in meters
function calculateDistanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth radius in meters
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a = Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
            Math.cos(phi1) * Math.cos(phi2) *
            Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

// Get current date string in YYYY-MM-DD
function getTodayDateString() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

// Database state
let db = {};

function initDb() {
  const today = getTodayDateString();
  
  // Create 5 historical attendance records prior to today
  const attendanceHistory = [];
  for (let i = 5; i >= 1; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dateStr = d.toISOString().split('T')[0];
    
    attendanceHistory.push({
      date: dateStr,
      status: "PRESENT",
      checkIn: {
        eventId: `evt-hist-in-${i}`,
        clientEventId: `client-uuid-in-${i}`,
        timestamp: `${dateStr}T09:05:00Z`,
        latitude: 12.971602,
        longitude: 77.594570
      },
      checkOut: {
        eventId: `evt-hist-out-${i}`,
        clientEventId: `client-uuid-out-${i}`,
        timestamp: `${dateStr}T18:15:00Z`,
        latitude: 12.971595,
        longitude: 77.594560
      },
      durationMinutes: 550
    });
  }

  db = {
    employee: {
      id: "EMP-001",
      name: "Alex Morgan",
      email: "alex.morgan@rebs.io",
      department: "Mobile Engineering",
      role: "Senior Flutter Engineer",
      avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150",
      officeConfig: OFFICE_CONFIG
    },
    // Map of date string -> attendance record
    attendance: {
      ...attendanceHistory.reduce((acc, item) => {
        acc[item.date] = item;
        return acc;
      }, {})
    },
    // Processed events map for idempotency: clientEventId -> saved response
    processedEvents: {},
    // Leave balances
    leaveBalance: {
      employeeId: "EMP-001",
      casual: {
        total: 12,
        used: 4,
        available: 8
      },
      sick: {
        total: 10,
        used: 3,
        available: 7
      },
      totalAvailable: 15
    },
    // Leave requests list
    leaveRequests: [
      {
        id: "LR-1001",
        employeeId: "EMP-001",
        leaveType: "CASUAL",
        startDate: "2026-11-04",
        endDate: "2026-11-05",
        days: 2,
        reason: "Attending annual family convention in Mysore",
        status: "APPROVED",
        createdAt: "2026-11-01T09:30:00Z"
      },
      {
        id: "LR-1002",
        employeeId: "EMP-001",
        leaveType: "SICK",
        startDate: "2026-11-12",
        endDate: "2026-11-13",
        days: 2,
        reason: "Acute viral fever with doctor advised rest",
        status: "APPROVED",
        createdAt: "2026-11-11T14:15:00Z"
      }
    ]
  };
}

initDb();

function addLog(method, path, status, bodySummary) {
  const logItem = {
    time: new Date().toLocaleTimeString(),
    method,
    path,
    status,
    summary: bodySummary || ''
  };
  requestLogs.unshift(logItem);
  if (requestLogs.length > 50) requestLogs.pop();
}

function sendJson(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-client-id'
  });
  res.end(JSON.stringify(data));
}

function sendError(res, statusCode, errorType, message) {
  sendJson(res, statusCode, {
    error: errorType,
    message: message,
    statusCode: statusCode,
    timestamp: new Date().toISOString()
  });
}

function parseJsonBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', () => {
      if (!body.trim()) return resolve({});
      try {
        const json = JSON.parse(body);
        resolve(json);
      } catch (err) {
        reject(new Error("Invalid JSON body"));
      }
    });
    req.on('error', err => reject(err));
  });
}

const server = http.createServer(async (req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const method = req.method;

  // Handle CORS Preflight
  if (method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-client-id'
    });
    res.end();
    return;
  }

  // Intercept for Scenarios (except for web control panel and control API)
  const isControlRoute = pathname === '/' || pathname.startsWith('/api/') || pathname.startsWith('/static/');
  
  if (!isControlRoute) {
    // 1. Timeout / Slow Response Scenario
    if (currentScenario === SCENARIOS.TIMEOUT) {
      console.log(`[TIMEOUT SIMULATION] Delaying request to ${pathname} by ${timeoutDelayMs}ms`);
      await new Promise(resolve => setTimeout(resolve, timeoutDelayMs));
    }

    // 2. Server Error Scenario
    if (currentScenario === SCENARIOS.SERVER_ERROR) {
      console.log(`[SERVER ERROR SIMULATION] Returning 500 for ${pathname}`);
      addLog(method, pathname, 500, "Simulated 500 Internal Server Error");
      sendError(res, 500, "InternalServerError", "Simulated internal server error in REBS HRMS cluster.");
      return;
    }
  }

  try {
    // Web Dashboard Control UI
    if (pathname === '/' && method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(renderDashboardHtml());
      return;
    }

    // Control APIs
    if (pathname === '/api/scenarios' && method === 'GET') {
      sendJson(res, 200, {
        currentScenario,
        timeoutDelayMs,
        availableScenarios: Object.values(SCENARIOS)
      });
      return;
    }

    if (pathname === '/api/scenarios' && method === 'POST') {
      const body = await parseJsonBody(req);
      if (body.scenario && Object.values(SCENARIOS).includes(body.scenario)) {
        currentScenario = body.scenario;
      }
      if (typeof body.timeoutDelayMs === 'number' && body.timeoutDelayMs > 0) {
        timeoutDelayMs = body.timeoutDelayMs;
      }
      addLog(method, pathname, 200, `Scenario changed to: ${currentScenario}`);
      sendJson(res, 200, {
        success: true,
        currentScenario,
        timeoutDelayMs
      });
      return;
    }

    if (pathname === '/api/reset' && method === 'POST') {
      initDb();
      currentScenario = SCENARIOS.NORMAL;
      addLog(method, pathname, 200, "Mock Database reset to initial seed state");
      sendJson(res, 200, { success: true, message: "Database reset to initial state" });
      return;
    }

    if (pathname === '/api/logs' && method === 'GET') {
      sendJson(res, 200, { logs: requestLogs });
      return;
    }

    // Section 5 Endpoints:

    // 1. GET /employee/me
    if (pathname === '/employee/me' && method === 'GET') {
      addLog(method, pathname, 200, "Fetched employee profile and office config");
      sendJson(res, 200, db.employee);
      return;
    }

    // 2. GET /attendance or /attendance?month=YYYY-MM
    if (pathname === '/attendance' && method === 'GET') {
      const monthFilter = parsedUrl.query.month; // e.g. "2026-11"
      let records = Object.values(db.attendance);
      
      if (monthFilter) {
        records = records.filter(r => r.date.startsWith(monthFilter));
      }
      
      // Sort newest to oldest
      records.sort((a, b) => b.date.localeCompare(a.date));

      addLog(method, pathname, 200, `Returned ${records.length} attendance records`);
      sendJson(res, 200, {
        records: records,
        total: records.length,
        companyTimezone: db.employee.officeConfig.companyTimezone
      });
      return;
    }

    // 3. POST /attendance/events
    if (pathname === '/attendance/events' && method === 'POST') {
      const body = await parseJsonBody(req);
      const { clientEventId, employeeId, type, timestamp, latitude, longitude } = body;

      // Idempotency check: If this exact clientEventId has already been processed, return cached response
      if (clientEventId && db.processedEvents[clientEventId]) {
        console.log(`[IDEMPOTENT RETRY] Client event ${clientEventId} already processed. Returning cached response.`);
        addLog(method, pathname, 200, `[IDEMPOTENT RETRY] Returned saved response for ${clientEventId}`);
        sendJson(res, 200, db.processedEvents[clientEventId]);
        return;
      }

      // Check scenario: Duplicate Conflict
      if (currentScenario === SCENARIOS.DUPLICATE_CONFLICT) {
        addLog(method, pathname, 409, "Simulated 409 Duplicate Attendance Conflict");
        sendError(res, 409, "Conflict", "Attendance event conflicts with existing record for today.");
        return;
      }

      // Validation: Required fields
      if (!clientEventId || !type || !timestamp || latitude === undefined || longitude === undefined) {
        addLog(method, pathname, 400, "Missing required fields");
        sendError(res, 400, "BadRequest", "Fields clientEventId, type, timestamp, latitude, and longitude are required.");
        return;
      }

      const eventDate = timestamp.split('T')[0];
      const office = db.employee.officeConfig;

      // Server-side Geofence Validation
      const distance = calculateDistanceMeters(latitude, longitude, office.latitude, office.longitude);
      if (distance > office.geofenceRadiusMeters) {
        addLog(method, pathname, 422, `Geofence violation: ${Math.round(distance)}m > ${office.geofenceRadiusMeters}m`);
        sendError(res, 422, "UnprocessableEntity", 
          `Device is outside the permitted office perimeter (${Math.round(distance)}m away; allowed: ${office.geofenceRadiusMeters}m).`
        );
        return;
      }

      // Check attendance session rules
      let dayRecord = db.attendance[eventDate];

      if (type === 'CHECK_IN') {
        if (dayRecord && dayRecord.checkIn) {
          // Already checked in today with a different event ID!
          addLog(method, pathname, 409, `Check-in rejected: already checked in on ${eventDate}`);
          sendError(res, 409, "Conflict", `Employee already checked in for date ${eventDate} at ${dayRecord.checkIn.timestamp}.`);
          return;
        }

        const newEventId = `evt-in-${Date.now()}`;
        const checkInEvent = {
          eventId: newEventId,
          clientEventId,
          timestamp,
          latitude,
          longitude
        };

        dayRecord = {
          date: eventDate,
          status: "CHECKED_IN",
          checkIn: checkInEvent,
          checkOut: null,
          durationMinutes: 0
        };

        db.attendance[eventDate] = dayRecord;

        const responseData = {
          success: true,
          event: checkInEvent,
          record: dayRecord,
          message: "Check-in recorded successfully"
        };

        // Save for idempotency
        db.processedEvents[clientEventId] = responseData;
        addLog(method, pathname, 201, `Check-in registered (${clientEventId})`);
        sendJson(res, 201, responseData);
        return;
      } 
      else if (type === 'CHECK_OUT') {
        if (!dayRecord || !dayRecord.checkIn) {
          // Check-out without check-in is rejected!
          addLog(method, pathname, 400, `Check-out rejected: no check-in found for ${eventDate}`);
          sendError(res, 400, "BadRequest", "Check-out is permitted only after check-in has been completed.");
          return;
        }

        if (dayRecord.checkOut) {
          addLog(method, pathname, 409, `Check-out rejected: already checked out on ${eventDate}`);
          sendError(res, 409, "Conflict", `Employee has already checked out for date ${eventDate}.`);
          return;
        }

        const newEventId = `evt-out-${Date.now()}`;
        const checkOutEvent = {
          eventId: newEventId,
          clientEventId,
          timestamp,
          latitude,
          longitude
        };

        // Calculate elapsed working duration in minutes
        const inTime = new Date(dayRecord.checkIn.timestamp).getTime();
        const outTime = new Date(timestamp).getTime();
        const durationMinutes = Math.max(0, Math.round((outTime - inTime) / (1000 * 60)));

        dayRecord.status = "CHECKED_OUT";
        dayRecord.checkOut = checkOutEvent;
        dayRecord.durationMinutes = durationMinutes;

        db.attendance[eventDate] = dayRecord;

        const responseData = {
          success: true,
          event: checkOutEvent,
          record: dayRecord,
          message: "Check-out recorded successfully"
        };

        // Save for idempotency
        db.processedEvents[clientEventId] = responseData;
        addLog(method, pathname, 201, `Check-out registered (${clientEventId})`);
        sendJson(res, 201, responseData);
        return;
      } else {
        sendError(res, 400, "BadRequest", `Unsupported event type: ${type}`);
        return;
      }
    }

    // 4. GET /leave/balance
    if (pathname === '/leave/balance' && method === 'GET') {
      addLog(method, pathname, 200, `Fetched leave balance (available: ${db.leaveBalance.totalAvailable})`);
      sendJson(res, 200, db.leaveBalance);
      return;
    }

    // 5. GET /leave/requests
    if (pathname === '/leave/requests' && method === 'GET') {
      addLog(method, pathname, 200, `Fetched ${db.leaveRequests.length} leave requests`);
      sendJson(res, 200, {
        requests: db.leaveRequests,
        total: db.leaveRequests.length
      });
      return;
    }

    // 6. POST /leave/requests
    if (pathname === '/leave/requests' && method === 'POST') {
      // Scenario Check: Server-side Leave Validation Rejection
      if (currentScenario === SCENARIOS.LEAVE_VALIDATION_ERROR) {
        addLog(method, pathname, 422, "Simulated 422 Leave Validation Rejection");
        sendError(res, 422, "UnprocessableEntity", 
          "Server-side leave validation rejection: Policy restriction prohibits leave during sprint freeze period."
        );
        return;
      }

      const body = await parseJsonBody(req);
      const { leaveType, startDate, endDate, reason } = body;

      // Rule: Reason must contain at least 10 non-whitespace characters
      const nonWhitespace = (reason || '').replace(/\s/g, '').length;
      if (nonWhitespace < 10) {
        addLog(method, pathname, 422, "Validation failed: Reason too short (<10 chars)");
        sendError(res, 422, "UnprocessableEntity", "Reason must contain at least 10 non-whitespace characters.");
        return;
      }

      // Rule: Start date cannot be before current company date
      const today = getTodayDateString();
      if (startDate < today) {
        addLog(method, pathname, 422, `Validation failed: Start date ${startDate} is in the past`);
        sendError(res, 422, "UnprocessableEntity", "Start date cannot be before current company date.");
        return;
      }

      // Rule: End date cannot be before start date
      if (endDate < startDate) {
        addLog(method, pathname, 422, "Validation failed: End date before start date");
        sendError(res, 422, "UnprocessableEntity", "End date cannot be before start date.");
        return;
      }

      // Calculate days (all calendar days count)
      const start = new Date(startDate);
      const end = new Date(endDate);
      const daysCount = Math.round((end - start) / (1000 * 60 * 60 * 24)) + 1;

      // Rule: Requested days cannot exceed available balance
      const typeKey = (leaveType || '').toLowerCase();
      const balanceObj = db.leaveBalance[typeKey];
      if (!balanceObj || daysCount > balanceObj.available) {
        addLog(method, pathname, 422, `Validation failed: Requested ${daysCount} days exceeds available ${balanceObj?.available || 0} days`);
        sendError(res, 422, "UnprocessableEntity", 
          `Requested days (${daysCount}) exceed available ${leaveType} balance (${balanceObj?.available || 0}).`
        );
        return;
      }

      // Rule: Dates cannot overlap an existing Pending or Approved request
      const hasOverlap = db.leaveRequests.some(existing => {
        if (existing.status !== 'APPROVED' && existing.status !== 'PENDING') return false;
        // Overlap condition: start <= existing.end && end >= existing.start
        return startDate <= existing.endDate && endDate >= existing.startDate;
      });

      if (hasOverlap) {
        addLog(method, pathname, 422, "Validation failed: Overlapping leave request");
        sendError(res, 422, "UnprocessableEntity", "Requested dates overlap with an existing Pending or Approved request.");
        return;
      }

      // Valid: Create Leave Request
      const newLeave = {
        id: `LR-${1000 + db.leaveRequests.length + 1}`,
        employeeId: db.employee.id,
        leaveType: leaveType.toUpperCase(),
        startDate,
        endDate,
        days: daysCount,
        reason,
        status: "PENDING",
        createdAt: new Date().toISOString()
      };

      // Deduct from balance
      balanceObj.available -= daysCount;
      balanceObj.used += daysCount;
      db.leaveBalance.totalAvailable -= daysCount;

      db.leaveRequests.unshift(newLeave);

      addLog(method, pathname, 201, `Leave application ${newLeave.id} submitted for ${daysCount} days`);
      sendJson(res, 201, {
        success: true,
        request: newLeave,
        updatedBalance: db.leaveBalance,
        message: "Leave application submitted successfully"
      });
      return;
    }

    // 404 Not Found
    addLog(method, pathname, 404, "Endpoint not found");
    sendError(res, 404, "NotFound", `Path ${pathname} not found on REBS HRMS mock server.`);

  } catch (err) {
    console.error("Server error:", err);
    addLog(method, pathname, 500, err.message);
    sendError(res, 500, "InternalServerError", err.message);
  }
});

// HTML Web Control Panel Dashboard
function renderDashboardHtml() {
  const scenarioBadges = {
    [SCENARIOS.NORMAL]: '<span class="badge bg-success">NORMAL (200 OK)</span>',
    [SCENARIOS.TIMEOUT]: '<span class="badge bg-warning text-dark">SLOW / TIMEOUT</span>',
    [SCENARIOS.SERVER_ERROR]: '<span class="badge bg-danger">500 SERVER ERROR</span>',
    [SCENARIOS.DUPLICATE_CONFLICT]: '<span class="badge bg-danger">409 DUPLICATE CONFLICT</span>',
    [SCENARIOS.LEAVE_VALIDATION_ERROR]: '<span class="badge bg-danger">422 LEAVE VALIDATION REJECT</span>',
  };

  const today = getTodayDateString();
  const todayAttendance = db.attendance[today];
  const todayStatus = todayAttendance 
    ? (todayAttendance.checkOut ? "Checked Out" : "Checked In") 
    : "Not Checked In";

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>REBS HRMS Mock Server & Control Panel</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
  <style>
    body { background-color: #f4f6f9; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    .card { border-radius: 12px; border: none; box-shadow: 0 4px 12px rgba(0,0,0,0.06); margin-bottom: 20px; }
    .status-pill { font-weight: 600; padding: 6px 14px; border-radius: 20px; font-size: 0.9rem; }
    .console-box { background: #1e1e24; color: #a5d6a7; border-radius: 8px; font-family: monospace; font-size: 0.85rem; max-height: 280px; overflow-y: auto; padding: 12px; }
    .scenario-btn { transition: all 0.2s; font-weight: 500; }
    .active-scenario { ring: 3px solid #0d6efd; font-weight: 700; transform: scale(1.02); }
  </style>
</head>
<body>
  <nav class="navbar navbar-dark bg-dark px-4 py-3">
    <div class="container-fluid">
      <span class="navbar-brand mb-0 h1">🏢 REBS HRMS Mock API Server</span>
      <div class="text-light">
        Current Scenario: ${scenarioBadges[currentScenario]}
      </div>
    </div>
  </nav>

  <div class="container-fluid px-4 py-4">
    <div class="row">
      <!-- Scenario Controller -->
      <div class="col-lg-5">
        <div class="card p-4">
          <h4 class="card-title mb-3">⚡ Scenario Simulation Controller</h4>
          <p class="text-muted small">Select a scenario below to test app handling of errors, offline queues, retries, and validation:</p>
          
          <div class="d-grid gap-2">
            <button class="btn btn-outline-success text-start py-2 scenario-btn ${currentScenario === 'normal' ? 'btn-success text-white' : ''}" onclick="setScenario('normal')">
              ✅ <strong>Normal Success (200 / 201)</strong>
              <div class="small opacity-75">All requests succeed immediately with standard data.</div>
            </button>

            <button class="btn btn-outline-warning text-dark text-start py-2 scenario-btn ${currentScenario === 'timeout' ? 'btn-warning' : ''}" onclick="setScenario('timeout')">
              ⏳ <strong>Slow Response / Timeout</strong>
              <div class="small opacity-75">Delays responses by ${timeoutDelayMs / 1000}s to trigger client Dio timeout & idempotency retry.</div>
            </button>

            <button class="btn btn-outline-danger text-start py-2 scenario-btn ${currentScenario === 'server_error' ? 'btn-danger text-white' : ''}" onclick="setScenario('server_error')">
              💥 <strong>500 Internal Server Error</strong>
              <div class="small opacity-75">Simulates backend cluster or DB crash on all API calls.</div>
            </button>

            <button class="btn btn-outline-danger text-start py-2 scenario-btn ${currentScenario === 'duplicate_conflict' ? 'btn-danger text-white' : ''}" onclick="setScenario('duplicate_conflict')">
              ⚠️ <strong>409 Duplicate Attendance Conflict</strong>
              <div class="small opacity-75">Simulates server rejecting event because attendance already exists.</div>
            </button>

            <button class="btn btn-outline-danger text-start py-2 scenario-btn ${currentScenario === 'leave_validation_error' ? 'btn-danger text-white' : ''}" onclick="setScenario('leave_validation_error')">
              📋 <strong>422 Leave Validation Rejection</strong>
              <div class="small opacity-75">Rejects leave submission with server-side validation error.</div>
            </button>
          </div>

          <hr class="my-3">

          <div class="d-flex align-items-center justify-content-between">
            <label class="form-label mb-0 small">Timeout Delay (ms):</label>
            <div class="input-group" style="width: 180px;">
              <input type="number" id="delayInput" class="form-control form-control-sm" value="${timeoutDelayMs}">
              <button class="btn btn-sm btn-outline-secondary" onclick="updateDelay()">Save</button>
            </div>
          </div>

          <div class="mt-3">
            <button class="btn btn-sm btn-outline-danger w-100" onclick="resetDb()">
              🔄 Reset Mock Database to Seed State
            </button>
          </div>
        </div>

        <!-- Realtime HTTP Logs -->
        <div class="card p-3">
          <div class="d-flex justify-content-between align-items-center mb-2">
            <h6 class="mb-0">📡 Incoming HTTP Traffic Logs</h6>
            <span class="badge bg-secondary">${requestLogs.length} events</span>
          </div>
          <div class="console-box" id="consoleLogs">
            ${requestLogs.map(l => `<div><span style="color:#64b5f6">[${l.time}]</span> <strong style="color:${l.status < 300 ? '#81c784' : l.status < 500 ? '#ffb74d' : '#e57373'}">${l.method} ${l.path} -> ${l.status}</strong> <span style="color:#bdbdbd">${l.summary}</span></div>`).join('') || '<div class="text-muted">No requests yet...</div>'}
          </div>
        </div>
      </div>

      <!-- State & Endpoints Info -->
      <div class="col-lg-7">
        <!-- Live Status Card -->
        <div class="card p-4">
          <h5>👤 Current Employee & Office Status</h5>
          <div class="row mt-2 g-3">
            <div class="col-sm-6">
              <div class="p-3 bg-light rounded">
                <div class="small text-muted">Employee</div>
                <strong>${db.employee.name} (${db.employee.id})</strong>
                <div class="small text-muted">${db.employee.department} • ${db.employee.role}</div>
              </div>
            </div>
            <div class="col-sm-6">
              <div class="p-3 bg-light rounded">
                <div class="small text-muted">Today's Attendance Status (${today})</div>
                <span class="badge ${todayStatus === 'Checked In' ? 'bg-primary' : todayStatus === 'Checked Out' ? 'bg-success' : 'bg-secondary'}">${todayStatus}</span>
                ${todayAttendance?.checkIn ? `<div class="small text-muted mt-1">In: ${new Date(todayAttendance.checkIn.timestamp).toLocaleTimeString()}</div>` : ''}
                ${todayAttendance?.checkOut ? `<div class="small text-muted">Out: ${new Date(todayAttendance.checkOut.timestamp).toLocaleTimeString()}</div>` : ''}
              </div>
            </div>
          </div>

          <div class="row mt-2 g-3">
            <div class="col-sm-6">
              <div class="p-3 bg-light rounded">
                <div class="small text-muted">Leave Balance</div>
                <strong>Casual: ${db.leaveBalance.casual.available}d</strong> | <strong>Sick: ${db.leaveBalance.sick.available}d</strong>
                <div class="small text-muted">Total Available: ${db.leaveBalance.totalAvailable} days</div>
              </div>
            </div>
            <div class="col-sm-6">
              <div class="p-3 bg-light rounded">
                <div class="small text-muted">Office Geofence Coordinates</div>
                <code>${OFFICE_CONFIG.latitude}, ${OFFICE_CONFIG.longitude}</code>
                <div class="small text-muted">Permitted Radius: ${OFFICE_CONFIG.geofenceRadiusMeters} meters</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Endpoints Reference -->
        <div class="card p-4">
          <h5>🔗 API Endpoints Reference</h5>
          <div class="table-responsive">
            <table class="table table-sm align-middle mb-0">
              <thead>
                <tr>
                  <th>Method</th>
                  <th>Endpoint</th>
                  <th>Description</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td><span class="badge bg-primary">GET</span></td>
                  <td><code><a href="/employee/me" target="_blank">/employee/me</a></code></td>
                  <td>Employee profile and office geofence config</td>
                </tr>
                <tr>
                  <td><span class="badge bg-primary">GET</span></td>
                  <td><code><a href="/attendance?month=2026-11" target="_blank">/attendance?month=YYYY-MM</a></code></td>
                  <td>Monthly attendance records & duration</td>
                </tr>
                <tr>
                  <td><span class="badge bg-success">POST</span></td>
                  <td><code>/attendance/events</code></td>
                  <td>Submit check-in/out (Idempotent via <code>clientEventId</code>)</td>
                </tr>
                <tr>
                  <td><span class="badge bg-primary">GET</span></td>
                  <td><code><a href="/leave/balance" target="_blank">/leave/balance</a></code></td>
                  <td>Current leave quota balances</td>
                </tr>
                <tr>
                  <td><span class="badge bg-primary">GET</span></td>
                  <td><code><a href="/leave/requests" target="_blank">/leave/requests</a></code></td>
                  <td>Leave requests history (Pending/Approved/Rejected)</td>
                </tr>
                <tr>
                  <td><span class="badge bg-success">POST</span></td>
                  <td><code>/leave/requests</code></td>
                  <td>Submit leave request with date & quota validation</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Idempotent Events in Memory -->
        <div class="card p-3">
          <h6>🔑 Processed Client Event IDs (Idempotency Cache)</h6>
          <div class="small text-muted mb-2">Total tracked: ${Object.keys(db.processedEvents).length} unique client UUIDs</div>
          <div style="max-height: 120px; overflow-y: auto;" class="bg-light p-2 rounded small font-monospace">
            ${Object.keys(db.processedEvents).length > 0 
              ? Object.keys(db.processedEvents).map(id => `<div>✓ ${id}</div>`).join('') 
              : '<div>No client events received yet</div>'}
          </div>
        </div>

      </div>
    </div>
  </div>

  <script>
    async function setScenario(scenario) {
      await fetch('/api/scenarios', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ scenario: scenario })
      });
      window.location.reload();
    }

    async function updateDelay() {
      const delay = parseInt(document.getElementById('delayInput').value);
      await fetch('/api/scenarios', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ timeoutDelayMs: delay })
      });
      alert('Timeout delay updated to ' + delay + 'ms');
    }

    async function resetDb() {
      if (confirm('Reset mock database to initial seed state?')) {
        await fetch('/api/reset', { method: 'POST' });
        window.location.reload();
      }
    }
  </script>
</body>
</html>`;
}

server.listen(PORT, HOST, () => {
  console.log(`====================================================`);
  console.log(`🚀 REBS HRMS Mock HTTP Server running on:`);
  console.log(`👉 Web Control Panel: http://localhost:${PORT}/`);
  console.log(`👉 Android Emulator Base URL: http://10.0.2.2:${PORT}`);
  console.log(`👉 Active Scenario: ${currentScenario}`);
  console.log(`====================================================`);
});
