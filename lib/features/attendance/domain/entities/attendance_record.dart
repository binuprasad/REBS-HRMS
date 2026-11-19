import 'package:equatable/equatable.dart';

enum TodayAttendanceStatus {
  notCheckedIn,
  checkedIn,
  checkedOut;

  String get displayName {
    switch (this) {
      case TodayAttendanceStatus.notCheckedIn:
        return 'Not Checked In';
      case TodayAttendanceStatus.checkedIn:
        return 'Checked In';
      case TodayAttendanceStatus.checkedOut:
        return 'Checked Out';
    }
  }
}

class AttendanceRecord extends Equatable {
  final String date; // YYYY-MM-DD
  final String status; // "PRESENT", "ABSENT", etc.
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final int durationMinutes;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;

  const AttendanceRecord({
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.durationMinutes = 0,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
  });

  TodayAttendanceStatus get sessionStatus {
    if (checkOutTime != null) {
      return TodayAttendanceStatus.checkedOut;
    } else if (checkInTime != null) {
      return TodayAttendanceStatus.checkedIn;
    }
    return TodayAttendanceStatus.notCheckedIn;
  }

  @override
  List<Object?> get props => [
        date,
        status,
        checkInTime,
        checkOutTime,
        durationMinutes,
        checkInLatitude,
        checkInLongitude,
        checkOutLatitude,
        checkOutLongitude,
      ];
}
