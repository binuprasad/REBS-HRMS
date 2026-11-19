import 'package:equatable/equatable.dart';
import 'sync_status.dart';

enum AttendanceEventType {
  checkIn,
  checkOut;

  String get value {
    switch (this) {
      case AttendanceEventType.checkIn:
        return 'CHECK_IN';
      case AttendanceEventType.checkOut:
        return 'CHECK_OUT';
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceEventType.checkIn:
        return 'Check In';
      case AttendanceEventType.checkOut:
        return 'Check Out';
    }
  }

  static AttendanceEventType fromString(String value) {
    if (value.toUpperCase() == 'CHECK_OUT') {
      return AttendanceEventType.checkOut;
    }
    return AttendanceEventType.checkIn;
  }
}

class AttendanceEvent extends Equatable {
  final String clientEventId; // UUID generated on client
  final String? serverEventId;
  final String employeeId;
  final AttendanceEventType type;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final SyncStatus syncStatus;
  final String? rejectionReason;
  final DateTime? syncedAt;
  final int retryCount;

  const AttendanceEvent({
    required this.clientEventId,
    this.serverEventId,
    required this.employeeId,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.syncStatus = SyncStatus.pendingSync,
    this.rejectionReason,
    this.syncedAt,
    this.retryCount = 0,
  });

  AttendanceEvent copyWith({
    String? clientEventId,
    String? serverEventId,
    String? employeeId,
    AttendanceEventType? type,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    SyncStatus? syncStatus,
    String? rejectionReason,
    DateTime? syncedAt,
    int? retryCount,
  }) {
    return AttendanceEvent(
      clientEventId: clientEventId ?? this.clientEventId,
      serverEventId: serverEventId ?? this.serverEventId,
      employeeId: employeeId ?? this.employeeId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      syncStatus: syncStatus ?? this.syncStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      syncedAt: syncedAt ?? this.syncedAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  List<Object?> get props => [
        clientEventId,
        serverEventId,
        employeeId,
        type,
        timestamp,
        latitude,
        longitude,
        syncStatus,
        rejectionReason,
        syncedAt,
        retryCount,
      ];
}
