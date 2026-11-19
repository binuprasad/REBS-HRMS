import '../../domain/entities/attendance_event.dart';
import '../../domain/entities/sync_status.dart';

class AttendanceEventModel extends AttendanceEvent {
  const AttendanceEventModel({
    required super.clientEventId,
    super.serverEventId,
    required super.employeeId,
    required super.type,
    required super.timestamp,
    required super.latitude,
    required super.longitude,
    super.syncStatus,
    super.rejectionReason,
    super.syncedAt,
    super.retryCount,
  });

  factory AttendanceEventModel.fromJson(Map<String, dynamic> json) {
    return AttendanceEventModel(
      clientEventId: json['clientEventId'] as String,
      serverEventId: json['serverEventId'] as String? ?? json['eventId'] as String?,
      employeeId: json['employeeId'] as String? ?? 'EMP-001',
      type: AttendanceEventType.fromString(json['type'] as String? ?? 'CHECK_IN'),
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      syncStatus: SyncStatus.fromString(json['syncStatus'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      syncedAt: json['syncedAt'] != null ? DateTime.parse(json['syncedAt'] as String) : null,
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientEventId': clientEventId,
      'serverEventId': serverEventId,
      'employeeId': employeeId,
      'type': type.value,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'syncStatus': syncStatus.name,
      'rejectionReason': rejectionReason,
      'syncedAt': syncedAt?.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'clientEventId': clientEventId,
      'employeeId': employeeId,
      'type': type.value,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory AttendanceEventModel.fromEntity(AttendanceEvent entity) {
    return AttendanceEventModel(
      clientEventId: entity.clientEventId,
      serverEventId: entity.serverEventId,
      employeeId: entity.employeeId,
      type: entity.type,
      timestamp: entity.timestamp,
      latitude: entity.latitude,
      longitude: entity.longitude,
      syncStatus: entity.syncStatus,
      rejectionReason: entity.rejectionReason,
      syncedAt: entity.syncedAt,
      retryCount: entity.retryCount,
    );
  }
}
