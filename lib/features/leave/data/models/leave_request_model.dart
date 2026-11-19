import '../../domain/entities/leave_request.dart';

class LeaveRequestModel extends LeaveRequest {
  const LeaveRequestModel({
    required super.id,
    required super.employeeId,
    required super.leaveType,
    required super.startDate,
    required super.endDate,
    required super.days,
    required super.reason,
    required super.status,
    required super.createdAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String? ?? 'EMP-001',
      leaveType: LeaveType.fromString(json['leaveType'] as String?),
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      days: json['days'] as int? ?? 1,
      reason: json['reason'] as String? ?? '',
      status: LeaveStatus.fromString(json['status'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'leaveType': leaveType.value,
      'startDate': startDate,
      'endDate': endDate,
      'days': days,
      'reason': reason,
      'status': status.name.toUpperCase(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'employeeId': employeeId,
      'leaveType': leaveType.value,
      'startDate': startDate,
      'endDate': endDate,
      'reason': reason,
    };
  }

  factory LeaveRequestModel.fromEntity(LeaveRequest entity) {
    return LeaveRequestModel(
      id: entity.id,
      employeeId: entity.employeeId,
      leaveType: entity.leaveType,
      startDate: entity.startDate,
      endDate: entity.endDate,
      days: entity.days,
      reason: entity.reason,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }
}
