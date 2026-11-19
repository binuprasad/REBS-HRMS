import 'package:rebs_hrms/core/storage/hive_service.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_request_model.dart';

abstract class LeaveLocalDataSource {
  Future<void> cacheLeaveBalance(LeaveBalanceModel balance);
  Future<LeaveBalanceModel?> getCachedLeaveBalance();

  Future<void> cacheLeaveRequests(List<LeaveRequestModel> requests);
  Future<List<LeaveRequestModel>> getCachedLeaveRequests();
  Future<void> addLeaveRequest(LeaveRequestModel request);
}

class LeaveLocalDataSourceImpl implements LeaveLocalDataSource {
  final HiveService hiveService;
  static const String _balanceKey = 'cached_leave_balance';
  static const String _requestsKey = 'cached_leave_requests';

  LeaveLocalDataSourceImpl({required this.hiveService});

  @override
  Future<void> cacheLeaveBalance(LeaveBalanceModel balance) async {
    await hiveService.leaveBox.put(_balanceKey, balance.toJson());
  }

  @override
  Future<LeaveBalanceModel?> getCachedLeaveBalance() async {
    final raw = hiveService.leaveBox.get(_balanceKey);
    if (raw == null) return null;
    return LeaveBalanceModel.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<void> cacheLeaveRequests(List<LeaveRequestModel> requests) async {
    final jsonList = requests.map((r) => r.toJson()).toList();
    await hiveService.leaveBox.put(_requestsKey, jsonList);
  }

  @override
  Future<List<LeaveRequestModel>> getCachedLeaveRequests() async {
    final raw = hiveService.leaveBox.get(_requestsKey);
    if (raw == null) return [];
    final list = raw as List<dynamic>;
    return list
        .map((item) => LeaveRequestModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<void> addLeaveRequest(LeaveRequestModel request) async {
    final current = await getCachedLeaveRequests();
    current.insert(0, request);
    await cacheLeaveRequests(current);
  }
}
