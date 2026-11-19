import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiEndpoints {
  // Dynamically detect default base URL based on platform
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    if (Platform.isAndroid) {
      // Android Emulator maps host machine's localhost to 10.0.2.2
      return 'http://10.0.2.2:8080';
    }
    // iOS Simulator, macOS, Linux, Windows
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
