import '../entities/attendance_event.dart';
import '../entities/attendance_record.dart';
import '../entities/attendance_result.dart';

abstract class AttendanceRepository {
  Future<AttendanceResult> checkIn({
    required double latitude,
    required double longitude,
  });

  Future<AttendanceResult> checkOut({
    required double latitude,
    required double longitude,
  });

  Future<List<AttendanceRecord>> getAttendanceHistory({
    String? month,
    bool forceRefresh = false,
  });

  Future<AttendanceRecord?> getTodayAttendanceRecord();

  Future<List<AttendanceEvent>> getPendingSyncEvents();

  Future<List<AttendanceEvent>> getAllStoredEvents();

  Future<SyncResult> syncPendingEvents();

  Stream<int> get pendingEventsCountStream;
}
