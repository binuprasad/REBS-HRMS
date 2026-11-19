import 'package:equatable/equatable.dart';
import 'package:rebs_hrms/features/attendance/domain/entities/attendance_record.dart';
import 'package:rebs_hrms/features/leave/domain/entities/leave_balance.dart';
import 'employee.dart';

class DashboardData extends Equatable {
  final Employee employee;
  final AttendanceRecord? todayRecord;
  final TodayAttendanceStatus todayStatus;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final int elapsedWorkingMinutes;
  final LeaveBalance? leaveBalance;
  final List<AttendanceRecord> recentAttendanceRecords;
  final bool isOffline;

  const DashboardData({
    required this.employee,
    this.todayRecord,
    required this.todayStatus,
    this.checkInTime,
    this.checkOutTime,
    this.elapsedWorkingMinutes = 0,
    this.leaveBalance,
    required this.recentAttendanceRecords,
    this.isOffline = false,
  });

  DashboardData copyWith({
    Employee? employee,
    AttendanceRecord? todayRecord,
    TodayAttendanceStatus? todayStatus,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    int? elapsedWorkingMinutes,
    LeaveBalance? leaveBalance,
    List<AttendanceRecord>? recentAttendanceRecords,
    bool? isOffline,
  }) {
    return DashboardData(
      employee: employee ?? this.employee,
      todayRecord: todayRecord ?? this.todayRecord,
      todayStatus: todayStatus ?? this.todayStatus,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      elapsedWorkingMinutes: elapsedWorkingMinutes ?? this.elapsedWorkingMinutes,
      leaveBalance: leaveBalance ?? this.leaveBalance,
      recentAttendanceRecords: recentAttendanceRecords ?? this.recentAttendanceRecords,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  List<Object?> get props => [
        employee,
        todayRecord,
        todayStatus,
        checkInTime,
        checkOutTime,
        elapsedWorkingMinutes,
        leaveBalance,
        recentAttendanceRecords,
        isOffline,
      ];
}
