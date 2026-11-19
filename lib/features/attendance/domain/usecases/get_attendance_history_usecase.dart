import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceHistoryUseCase {
  final AttendanceRepository repository;

  GetAttendanceHistoryUseCase(this.repository);

  Future<List<AttendanceRecord>> execute({
    String? month,
    bool forceRefresh = false,
  }) {
    return repository.getAttendanceHistory(
      month: month,
      forceRefresh: forceRefresh,
    );
  }
}
