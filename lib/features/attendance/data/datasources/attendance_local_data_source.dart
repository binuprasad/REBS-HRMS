import 'dart:async';
import 'package:rebs_hrms/core/storage/hive_service.dart';
import '../../domain/entities/sync_status.dart';
import '../models/attendance_event_model.dart';
import '../models/attendance_record_model.dart';

abstract class AttendanceLocalDataSource {
  Future<void> cacheAttendanceRecords(List<AttendanceRecordModel> records);
  Future<List<AttendanceRecordModel>> getCachedAttendanceRecords({String? month});
  
  Future<void> saveAttendanceRecord(AttendanceRecordModel record);
  Future<AttendanceRecordModel?> getAttendanceRecordByDate(String dateStr);

  Future<void> saveEvent(AttendanceEventModel event);
  Future<void> updateEvent(AttendanceEventModel event);
  Future<AttendanceEventModel?> getEvent(String clientEventId);
  Future<List<AttendanceEventModel>> getAllEvents();
  Future<List<AttendanceEventModel>> getPendingEvents();
  Future<void> deleteEvent(String clientEventId);

  Stream<int> get pendingCountStream;
}

class AttendanceLocalDataSourceImpl implements AttendanceLocalDataSource {
  final HiveService hiveService;
  final _pendingCountController = StreamController<int>.broadcast();

  AttendanceLocalDataSourceImpl({required this.hiveService}) {
    _emitPendingCount();
  }

  void _emitPendingCount() {
    final count = _getPendingEventsSync().length;
    _pendingCountController.add(count);
  }

  @override
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  @override
  Future<void> cacheAttendanceRecords(List<AttendanceRecordModel> records) async {
    final box = hiveService.attendanceBox;
    for (final record in records) {
      await box.put(record.date, record.toJson());
    }
  }

  @override
  Future<List<AttendanceRecordModel>> getCachedAttendanceRecords({String? month}) async {
    final box = hiveService.attendanceBox;
    final records = <AttendanceRecordModel>[];

    for (final key in box.keys) {
      final keyStr = key.toString();
      if (month != null && !keyStr.startsWith(month)) {
        continue;
      }
      final raw = box.get(key);
      if (raw != null) {
        records.add(AttendanceRecordModel.fromJson(Map<String, dynamic>.from(raw as Map)));
      }
    }

    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  @override
  Future<void> saveAttendanceRecord(AttendanceRecordModel record) async {
    final box = hiveService.attendanceBox;
    await box.put(record.date, record.toJson());
  }

  @override
  Future<AttendanceRecordModel?> getAttendanceRecordByDate(String dateStr) async {
    final box = hiveService.attendanceBox;
    final raw = box.get(dateStr);
    if (raw == null) return null;
    return AttendanceRecordModel.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<void> saveEvent(AttendanceEventModel event) async {
    final box = hiveService.attendanceEventsBox;
    await box.put(event.clientEventId, event.toJson());
    _emitPendingCount();
  }

  @override
  Future<void> updateEvent(AttendanceEventModel event) async {
    final box = hiveService.attendanceEventsBox;
    await box.put(event.clientEventId, event.toJson());
    _emitPendingCount();
  }

  @override
  Future<AttendanceEventModel?> getEvent(String clientEventId) async {
    final box = hiveService.attendanceEventsBox;
    final raw = box.get(clientEventId);
    if (raw == null) return null;
    return AttendanceEventModel.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<List<AttendanceEventModel>> getAllEvents() async {
    final box = hiveService.attendanceEventsBox;
    final events = <AttendanceEventModel>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        events.add(AttendanceEventModel.fromJson(Map<String, dynamic>.from(raw as Map)));
      }
    }
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return events;
  }

  List<AttendanceEventModel> _getPendingEventsSync() {
    final box = hiveService.attendanceEventsBox;
    final pending = <AttendanceEventModel>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        final model = AttendanceEventModel.fromJson(Map<String, dynamic>.from(raw as Map));
        if (model.syncStatus == SyncStatus.pendingSync) {
          pending.add(model);
        }
      }
    }
    // Strict FIFO ordering by timestamp
    pending.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return pending;
  }

  @override
  Future<List<AttendanceEventModel>> getPendingEvents() async {
    return _getPendingEventsSync();
  }

  @override
  Future<void> deleteEvent(String clientEventId) async {
    final box = hiveService.attendanceEventsBox;
    await box.delete(clientEventId);
    _emitPendingCount();
  }
}
