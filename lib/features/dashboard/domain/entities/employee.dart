import 'package:equatable/equatable.dart';

class OfficeConfig extends Equatable {
  final String name;
  final double latitude;
  final double longitude;
  final double geofenceRadiusMeters;
  final String companyTimezone;
  final String workStartTime;
  final String workEndTime;

  const OfficeConfig({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadiusMeters,
    required this.companyTimezone,
    required this.workStartTime,
    required this.workEndTime,
  });

  @override
  List<Object?> get props => [
        name,
        latitude,
        longitude,
        geofenceRadiusMeters,
        companyTimezone,
        workStartTime,
        workEndTime,
      ];
}

class Employee extends Equatable {
  final String id;
  final String name;
  final String email;
  final String department;
  final String role;
  final String? avatarUrl;
  final OfficeConfig officeConfig;

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    this.avatarUrl,
    required this.officeConfig,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        department,
        role,
        avatarUrl,
        officeConfig,
      ];
}
