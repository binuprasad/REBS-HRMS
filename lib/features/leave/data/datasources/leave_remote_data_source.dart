import 'package:rebs_hrms/core/constants/api_endpoints.dart';
import 'package:rebs_hrms/core/network/dio_client.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_request_model.dart';

abstract class LeaveRemoteDataSource {
  Future<LeaveBalanceModel> getLeaveBalance();
  Future<List<LeaveRequestModel>> getLeaveRequests();
  Future<LeaveRequestModel> submitLeaveRequest(Map<String, dynamic> payload);
}

class LeaveRemoteDataSourceImpl implements LeaveRemoteDataSource {
  final DioClient dioClient;

  LeaveRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<LeaveBalanceModel> getLeaveBalance() async {
    final response = await dioClient.get(ApiEndpoints.leaveBalance);
    return LeaveBalanceModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<List<LeaveRequestModel>> getLeaveRequests() async {
    final response = await dioClient.get(ApiEndpoints.leaveRequests);
    final data = response.data as Map<String, dynamic>;
    final list = (data['requests'] as List<dynamic>?) ?? [];
    return list
        .map((item) => LeaveRequestModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<LeaveRequestModel> submitLeaveRequest(Map<String, dynamic> payload) async {
    final response = await dioClient.post(
      ApiEndpoints.leaveRequests,
      data: payload,
    );
    final data = response.data as Map<String, dynamic>;
    final requestMap = data['request'] as Map<String, dynamic>;
    return LeaveRequestModel.fromJson(requestMap);
  }
}
