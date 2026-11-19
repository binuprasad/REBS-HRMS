import 'package:equatable/equatable.dart';

enum LeaveType {
  casual,
  sick;

  String get value {
    switch (this) {
      case LeaveType.casual:
        return 'CASUAL';
      case LeaveType.sick:
        return 'SICK';
    }
  }

  String get displayName {
    switch (this) {
      case LeaveType.casual:
        return 'Casual Leave';
      case LeaveType.sick:
        return 'Sick Leave';
    }
  }

  static LeaveType fromString(String? value) {
    if (value?.toUpperCase() == 'SICK') {
      return LeaveType.sick;
    }
    return LeaveType.casual;
  }
}

enum LeaveStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }

  static LeaveStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'APPROVED':
        return LeaveStatus.approved;
      case 'REJECTED':
        return LeaveStatus.rejected;
      case 'PENDING':
      default:
        return LeaveStatus.pending;
    }
  }
}

class LeaveRequest extends Equatable {
  final String id;
  final String employeeId;
  final LeaveType leaveType;
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  final int days;
  final String reason;
  final LeaveStatus status;
  final DateTime createdAt;

  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        employeeId,
        leaveType,
        startDate,
        endDate,
        days,
        reason,
        status,
        createdAt,
      ];
}
