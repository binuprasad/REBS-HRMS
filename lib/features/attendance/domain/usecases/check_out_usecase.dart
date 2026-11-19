import '../entities/attendance_result.dart';
import '../repositories/attendance_repository.dart';

class CheckOutUseCase {
  final AttendanceRepository repository;

  CheckOutUseCase(this.repository);

  Future<AttendanceResult> execute({
    required double latitude,
    required double longitude,
  }) {
    return repository.checkOut(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
