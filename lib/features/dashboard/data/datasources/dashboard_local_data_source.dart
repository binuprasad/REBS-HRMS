import 'package:rebs_hrms/core/storage/hive_service.dart';
import 'package:rebs_hrms/features/dashboard/data/models/employee_model.dart';

abstract class DashboardLocalDataSource {
  Future<void> cacheEmployeeProfile(EmployeeModel employee);
  Future<EmployeeModel?> getCachedEmployeeProfile();
  Future<void> cacheDashboardJson(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getCachedDashboardJson();
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  final HiveService hiveService;
  static const String _keyProfile = 'cached_employee_profile';
  static const String _keyDashboard = 'cached_dashboard_summary';

  DashboardLocalDataSourceImpl({required this.hiveService});

  @override
  Future<void> cacheEmployeeProfile(EmployeeModel employee) async {
    await hiveService.dashboardBox.put(_keyProfile, employee.toJson());
  }

  @override
  Future<EmployeeModel?> getCachedEmployeeProfile() async {
    final raw = hiveService.dashboardBox.get(_keyProfile);
    if (raw == null) return null;
    return EmployeeModel.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<void> cacheDashboardJson(Map<String, dynamic> data) async {
    await hiveService.dashboardBox.put(_keyDashboard, data);
  }

  @override
  Future<Map<String, dynamic>?> getCachedDashboardJson() async {
    final raw = hiveService.dashboardBox.get(_keyDashboard);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }
}
