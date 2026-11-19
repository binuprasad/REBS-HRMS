class AppConstants {
  static const String appName = 'REBS HRMS';
  
  // Default Preconfigured Employee
  static const String defaultEmployeeId = 'EMP-001';
  static const String defaultEmployeeName = 'Alex Morgan';
  static const String defaultDepartment = 'Mobile Engineering';

  // Office Geofence Defaults (Bangalore REBS HQ)
  static const double defaultOfficeLatitude = 12.971598;
  static const double defaultOfficeLongitude = 77.594566;
  static const double permittedGeofenceRadiusMeters = 200.0;
  static const String defaultCompanyTimezone = 'Asia/Kolkata';

  // Network timeouts
  static const int connectTimeoutMs = 8000;
  static const int receiveTimeoutMs = 8000;
  static const int sendTimeoutMs = 8000;

  // Leave Form Rules
  static const int minReasonLength = 10;
}
