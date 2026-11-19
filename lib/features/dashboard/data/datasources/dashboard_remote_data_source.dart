import 'package:rebs_hrms/core/constants/api_endpoints.dart';
import 'package:rebs_hrms/core/network/dio_client.dart';
import 'package:rebs_hrms/features/attendance/data/models/attendance_record_model.dart';
import 'package:rebs_hrms/features/dashboard/data/models/employee_model.dart';
import 'package:rebs_hrms/features/leave/data/models/leave_balance_model.dart';

abstract class DashboardRemoteDataSource {
  Future<EmployeeModel> getEmployeeProfile();
  Future<List<AttendanceRecordModel>> getRecentAttendance();
  Future<LeaveBalanceModel> getLeaveBalance();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient dioClient;

  DashboardRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<EmployeeModel> getEmployeeProfile() async {
    final response = await dioClient.get(ApiEndpoints.employeeMe);
    return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<AttendanceRecordModel>> getRecentAttendance() async {
    final response = await dioClient.get(ApiEndpoints.attendance);
    final data = response.data as Map<String, dynamic>;
    final recordsList = (data['records'] as List<dynamic>?) ?? [];
    return recordsList
        .map((r) => AttendanceRecordModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LeaveBalanceModel> getLeaveBalance() async {
    final response = await dioClient.get(ApiEndpoints.leaveBalance);
    return LeaveBalanceModel.fromJson(response.data as Map<String, dynamic>);
  }
}
