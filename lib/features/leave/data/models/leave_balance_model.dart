import '../../domain/entities/leave_balance.dart';

class LeaveTypeBalanceModel extends LeaveTypeBalance {
  const LeaveTypeBalanceModel({
    required super.total,
    required super.used,
    required super.available,
  });

  factory LeaveTypeBalanceModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeBalanceModel(
      total: json['total'] as int? ?? 0,
      used: json['used'] as int? ?? 0,
      available: json['available'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'used': used,
      'available': available,
    };
  }
}

class LeaveBalanceModel extends LeaveBalance {
  const LeaveBalanceModel({
    required super.employeeId,
    required super.casual,
    required super.sick,
    required super.totalAvailable,
  });

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    final casualJson = json['casual'] as Map<String, dynamic>? ?? {};
    final sickJson = json['sick'] as Map<String, dynamic>? ?? {};

    return LeaveBalanceModel(
      employeeId: json['employeeId'] as String? ?? 'EMP-001',
      casual: LeaveTypeBalanceModel.fromJson(casualJson),
      sick: LeaveTypeBalanceModel.fromJson(sickJson),
      totalAvailable: json['totalAvailable'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'casual': (casual as LeaveTypeBalanceModel).toJson(),
      'sick': (sick as LeaveTypeBalanceModel).toJson(),
      'totalAvailable': totalAvailable,
    };
  }
}
