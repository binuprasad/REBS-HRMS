import '../entities/attendance_result.dart';
import '../repositories/attendance_repository.dart';

class SyncAttendanceEventsUseCase {
  final AttendanceRepository repository;

  SyncAttendanceEventsUseCase(this.repository);

  Future<SyncResult> execute() {
    return repository.syncPendingEvents();
  }
}
