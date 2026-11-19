import '../entities/leave_balance.dart';
import '../entities/leave_request.dart';

abstract class LeaveRepository {
  Future<LeaveBalance> getLeaveBalance({bool forceRefresh = false});
  Future<List<LeaveRequest>> getLeaveRequests({bool forceRefresh = false});
  Future<LeaveRequest> submitLeaveRequest({
    required LeaveType leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  });
}
