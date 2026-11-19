import '../../domain/entities/employee.dart';

class OfficeConfigModel extends OfficeConfig {
  const OfficeConfigModel({
    required super.name,
    required super.latitude,
    required super.longitude,
    required super.geofenceRadiusMeters,
    required super.companyTimezone,
    required super.workStartTime,
    required super.workEndTime,
  });

  factory OfficeConfigModel.fromJson(Map<String, dynamic> json) {
    return OfficeConfigModel(
      name: json['name'] as String? ?? 'REBS Office',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 12.971598,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.594566,
      geofenceRadiusMeters: (json['geofenceRadiusMeters'] as num?)?.toDouble() ?? 200.0,
      companyTimezone: json['companyTimezone'] as String? ?? 'Asia/Kolkata',
      workStartTime: json['workStartTime'] as String? ?? '09:00',
      workEndTime: json['workEndTime'] as String? ?? '18:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'geofenceRadiusMeters': geofenceRadiusMeters,
      'companyTimezone': companyTimezone,
      'workStartTime': workStartTime,
      'workEndTime': workEndTime,
    };
  }
}

class EmployeeModel extends Employee {
  const EmployeeModel({
    required super.id,
    required super.name,
    required super.email,
    required super.department,
    required super.role,
    super.avatarUrl,
    required super.officeConfig,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final officeJson = json['officeConfig'] as Map<String, dynamic>? ?? {};
    return EmployeeModel(
      id: json['id'] as String? ?? 'EMP-001',
      name: json['name'] as String? ?? 'Alex Morgan',
      email: json['email'] as String? ?? 'alex.morgan@rebs.io',
      department: json['department'] as String? ?? 'Mobile Engineering',
      role: json['role'] as String? ?? 'Senior Flutter Engineer',
      avatarUrl: json['avatarUrl'] as String?,
      officeConfig: OfficeConfigModel.fromJson(officeJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
      'role': role,
      'avatarUrl': avatarUrl,
      'officeConfig': (officeConfig as OfficeConfigModel).toJson(),
    };
  }
}
