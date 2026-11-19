import '../../domain/entities/attendance_record.dart';

class AttendanceRecordModel extends AttendanceRecord {
  const AttendanceRecordModel({
    required super.date,
    required super.status,
    super.checkInTime,
    super.checkOutTime,
    super.durationMinutes,
    super.checkInLatitude,
    super.checkInLongitude,
    super.checkOutLatitude,
    super.checkOutLongitude,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    final checkInMap = json['checkIn'] as Map<String, dynamic>?;
    final checkOutMap = json['checkOut'] as Map<String, dynamic>?;

    DateTime? checkInTime;
    double? checkInLatitude;
    double? checkInLongitude;
    if (checkInMap != null && checkInMap['timestamp'] != null) {
      checkInTime = DateTime.parse(checkInMap['timestamp'] as String);
      checkInLatitude = (checkInMap['latitude'] as num?)?.toDouble();
      checkInLongitude = (checkInMap['longitude'] as num?)?.toDouble();
    }

    DateTime? checkOutTime;
    double? checkOutLatitude;
    double? checkOutLongitude;
    if (checkOutMap != null && checkOutMap['timestamp'] != null) {
      checkOutTime = DateTime.parse(checkOutMap['timestamp'] as String);
      checkOutLatitude = (checkOutMap['latitude'] as num?)?.toDouble();
      checkOutLongitude = (checkOutMap['longitude'] as num?)?.toDouble();
    }

    return AttendanceRecordModel(
      date: json['date'] as String,
      status: json['status'] as String? ?? 'PRESENT',
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      checkInLatitude: checkInLatitude,
      checkInLongitude: checkInLongitude,
      checkOutLatitude: checkOutLatitude,
      checkOutLongitude: checkOutLongitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'status': status,
      'checkIn': checkInTime != null
          ? {
              'timestamp': checkInTime!.toIso8601String(),
              'latitude': checkInLatitude,
              'longitude': checkInLongitude,
            }
          : null,
      'checkOut': checkOutTime != null
          ? {
              'timestamp': checkOutTime!.toIso8601String(),
              'latitude': checkOutLatitude,
              'longitude': checkOutLongitude,
            }
          : null,
      'durationMinutes': durationMinutes,
    };
  }

  factory AttendanceRecordModel.fromEntity(AttendanceRecord entity) {
    return AttendanceRecordModel(
      date: entity.date,
      status: entity.status,
      checkInTime: entity.checkInTime,
      checkOutTime: entity.checkOutTime,
      durationMinutes: entity.durationMinutes,
      checkInLatitude: entity.checkInLatitude,
      checkInLongitude: entity.checkInLongitude,
      checkOutLatitude: entity.checkOutLatitude,
      checkOutLongitude: entity.checkOutLongitude,
    );
  }
}
