import '../entities/leave_balance.dart';
import '../repositories/leave_repository.dart';

class GetLeaveBalanceUseCase {
  final LeaveRepository repository;

  GetLeaveBalanceUseCase(this.repository);

  Future<LeaveBalance> execute({bool forceRefresh = false}) {
    return repository.getLeaveBalance(forceRefresh: forceRefresh);
  }
}
