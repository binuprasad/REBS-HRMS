import '../entities/leave_request.dart';
import '../repositories/leave_repository.dart';

class GetLeaveRequestsUseCase {
  final LeaveRepository repository;

  GetLeaveRequestsUseCase(this.repository);

  Future<List<LeaveRequest>> execute({bool forceRefresh = false}) {
    return repository.getLeaveRequests(forceRefresh: forceRefresh);
  }
}
