import '../entities/attendance_event.dart';
import '../repositories/attendance_repository.dart';

class GetPendingEventsUseCase {
  final AttendanceRepository repository;

  GetPendingEventsUseCase(this.repository);

  Future<List<AttendanceEvent>> execute() {
    return repository.getPendingSyncEvents();
  }

  Stream<int> watchCount() {
    return repository.pendingEventsCountStream;
  }
}
