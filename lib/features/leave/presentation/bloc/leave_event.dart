import 'package:equatable/equatable.dart';
import '../../domain/entities/leave_request.dart';

abstract class LeaveEvent extends Equatable {
  const LeaveEvent();

  @override
  List<Object?> get props => [];
}

class LoadLeaveData extends LeaveEvent {
  final bool forceRefresh;

  const LoadLeaveData({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class SubmitLeaveApplication extends LeaveEvent {
  final LeaveType leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;

  const SubmitLeaveApplication({
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });

  @override
  List<Object?> get props => [leaveType, startDate, endDate, reason];
}

class ResetLeaveSubmissionState extends LeaveEvent {
  const ResetLeaveSubmissionState();
}
