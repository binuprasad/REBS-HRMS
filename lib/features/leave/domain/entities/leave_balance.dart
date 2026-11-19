import 'package:equatable/equatable.dart';

class LeaveTypeBalance extends Equatable {
  final int total;
  final int used;
  final int available;

  const LeaveTypeBalance({
    required this.total,
    required this.used,
    required this.available,
  });

  @override
  List<Object?> get props => [total, used, available];
}

class LeaveBalance extends Equatable {
  final String employeeId;
  final LeaveTypeBalance casual;
  final LeaveTypeBalance sick;
  final int totalAvailable;

  const LeaveBalance({
    required this.employeeId,
    required this.casual,
    required this.sick,
    required this.totalAvailable,
  });

  @override
  List<Object?> get props => [employeeId, casual, sick, totalAvailable];
}
