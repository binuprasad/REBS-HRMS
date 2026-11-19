import '../entities/attendance_result.dart';
import '../repositories/attendance_repository.dart';

class CheckInUseCase {
  final AttendanceRepository repository;

  CheckInUseCase(this.repository);

  Future<AttendanceResult> execute({
    required double latitude,
    required double longitude,
  }) {
    return repository.checkIn(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
