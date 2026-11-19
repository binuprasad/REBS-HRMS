class ApiEndpoints {
  // Dynamically detect default base URL based on platform
  static String get defaultBaseUrl {
    // Default to localhost:8080 (works with adb reverse on devices, local desktop & web)
    return 'http://localhost:8080';
  }

  // Endpoints from Section 5 of specification
  static const String employeeMe = '/employee/me';
  static const String attendance = '/attendance';
  static const String attendanceEvents = '/attendance/events';
  static const String leaveBalance = '/leave/balance';
  static const String leaveRequests = '/leave/requests';

  // Mock server control endpoints
  static const String scenarios = '/api/scenarios';
  static const String reset = '/api/reset';
}
