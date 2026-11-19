import '../entities/dashboard_data.dart';
import '../entities/employee.dart';

abstract class DashboardRepository {
  Future<DashboardData> getDashboardData({bool forceRefresh = false});
  Future<Employee> getEmployeeProfile({bool forceRefresh = false});
  Future<DashboardData?> getCachedDashboardData();
}
