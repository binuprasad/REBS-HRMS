import 'package:equatable/equatable.dart';
import 'attendance_event.dart';
import 'attendance_record.dart';

class AttendanceResult extends Equatable {
  final bool success;
  final AttendanceEvent event;
  final AttendanceRecord? record;
  final String message;
  final bool isOffline;

  const AttendanceResult({
    required this.success,
    required this.event,
    this.record,
    required this.message,
    this.isOffline = false,
  });

  @override
  List<Object?> get props => [success, event, record, message, isOffline];
}

class SyncResult extends Equatable {
  final int syncedCount;
  final int rejectedCount;
  final int totalProcessed;
  final List<String> errors;

  const SyncResult({
    required this.syncedCount,
    required this.rejectedCount,
    required this.totalProcessed,
    this.errors = const [],
  });

  bool get hasFailures => rejectedCount > 0 || errors.isNotEmpty;

  @override
  List<Object?> get props => [syncedCount, rejectedCount, totalProcessed, errors];
}
