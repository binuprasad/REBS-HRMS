import 'package:rebs_hrms/core/error/exceptions.dart';
import 'package:rebs_hrms/core/error/failures.dart';
import 'package:rebs_hrms/core/network/network_info.dart';
import 'package:rebs_hrms/core/utils/date_time_utils.dart';
import 'package:rebs_hrms/features/attendance/data/models/attendance_record_model.dart';
import 'package:rebs_hrms/features/attendance/domain/entities/attendance_record.dart';
import 'package:rebs_hrms/features/dashboard/data/datasources/dashboard_local_data_source.dart';
import 'package:rebs_hrms/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:rebs_hrms/features/dashboard/data/models/employee_model.dart';
import 'package:rebs_hrms/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:rebs_hrms/features/dashboard/domain/entities/employee.dart';
import 'package:rebs_hrms/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:rebs_hrms/features/leave/data/models/leave_balance_model.dart';
import 'package:rebs_hrms/features/leave/domain/entities/leave_balance.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final DashboardLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<DashboardData> getDashboardData({bool forceRefresh = false}) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        final profileModel = await remoteDataSource.getEmployeeProfile();
        await localDataSource.cacheEmployeeProfile(profileModel);

        final attendanceModels = await remoteDataSource.getRecentAttendance();
        final balanceModel = await remoteDataSource.getLeaveBalance();

        final todayStr = DateTimeUtils.toDateString(DateTime.now());
        AttendanceRecord? todayRecord;
        try {
          todayRecord = attendanceModels.firstWhere((r) => r.date == todayStr);
        } catch (_) {
          todayRecord = null;
        }

        final todayStatus = todayRecord?.sessionStatus ?? TodayAttendanceStatus.notCheckedIn;
        final elapsedMinutes = _calculateElapsedMinutes(todayRecord);

        // Take latest 5 attendance records
        final latestFive = attendanceModels.take(5).toList();

        final dashboard = DashboardData(
          employee: profileModel,
          todayRecord: todayRecord,
          todayStatus: todayStatus,
          checkInTime: todayRecord?.checkInTime,
          checkOutTime: todayRecord?.checkOutTime,
          elapsedWorkingMinutes: elapsedMinutes,
          leaveBalance: balanceModel,
          recentAttendanceRecords: latestFive,
          isOffline: false,
        );

        // Cache dashboard snapshot
        await _cacheDashboardSnapshot(dashboard);

        return dashboard;
      } catch (e) {
        // Fall back to cache on remote error
        final cached = await getCachedDashboardData();
        if (cached != null) {
          return cached.copyWith(isOffline: true);
        }
        if (e is ServerException) {
          throw ServerFailure(e.message, e.statusCode);
        }
        throw ServerFailure(e.toString());
      }
    } else {
      // Offline mode
      final cached = await getCachedDashboardData();
      if (cached != null) {
        return cached.copyWith(isOffline: true);
      }
      throw const NetworkFailure(
        'You are offline and no cached dashboard data is available. Please connect to internet.',
      );
    }
  }

  @override
  Future<Employee> getEmployeeProfile({bool forceRefresh = false}) async {
    final isConnected = await networkInfo.isConnected;
    if (isConnected) {
      try {
        final profile = await remoteDataSource.getEmployeeProfile();
        await localDataSource.cacheEmployeeProfile(profile);
        return profile;
      } catch (_) {
        final cached = await localDataSource.getCachedEmployeeProfile();
        if (cached != null) return cached;
        rethrow;
      }
    } else {
      final cached = await localDataSource.getCachedEmployeeProfile();
      if (cached != null) return cached;
      throw const NetworkFailure('No cached employee profile found offline.');
    }
  }

  @override
  Future<DashboardData?> getCachedDashboardData() async {
    final cachedJson = await localDataSource.getCachedDashboardJson();
    if (cachedJson == null) return null;

    try {
      final employee = EmployeeModel.fromJson(
        Map<String, dynamic>.from(cachedJson['employee'] as Map),
      );

      AttendanceRecord? todayRecord;
      if (cachedJson['todayRecord'] != null) {
        todayRecord = AttendanceRecordModel.fromJson(
          Map<String, dynamic>.from(cachedJson['todayRecord'] as Map),
        );
      }

      LeaveBalance? leaveBalance;
      if (cachedJson['leaveBalance'] != null) {
        leaveBalance = LeaveBalanceModel.fromJson(
          Map<String, dynamic>.from(cachedJson['leaveBalance'] as Map),
        );
      }

      final recentListRaw = (cachedJson['recentAttendanceRecords'] as List<dynamic>?) ?? [];
      final recentRecords = recentListRaw
          .map((item) => AttendanceRecordModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      final todayStatus = todayRecord?.sessionStatus ?? TodayAttendanceStatus.notCheckedIn;
      final elapsedMinutes = _calculateElapsedMinutes(todayRecord);

      return DashboardData(
        employee: employee,
        todayRecord: todayRecord,
        todayStatus: todayStatus,
        checkInTime: todayRecord?.checkInTime,
        checkOutTime: todayRecord?.checkOutTime,
        elapsedWorkingMinutes: elapsedMinutes,
        leaveBalance: leaveBalance,
        recentAttendanceRecords: recentRecords,
        isOffline: true,
      );
    } catch (_) {
      return null;
    }
  }

  int _calculateElapsedMinutes(AttendanceRecord? record) {
    if (record == null || record.checkInTime == null) return 0;
    if (record.checkOutTime != null) {
      return record.durationMinutes;
    }
    // Still checked in: calculate live difference to now
    final now = DateTime.now();
    final inTime = record.checkInTime!;
    final diff = now.difference(inTime).inMinutes;
    return diff > 0 ? diff : 0;
  }

  Future<void> _cacheDashboardSnapshot(DashboardData data) async {
    final json = {
      'employee': (data.employee as EmployeeModel).toJson(),
      'todayRecord': data.todayRecord != null
          ? AttendanceRecordModel.fromEntity(data.todayRecord!).toJson()
          : null,
      'leaveBalance': data.leaveBalance != null
          ? (data.leaveBalance as LeaveBalanceModel).toJson()
          : null,
      'recentAttendanceRecords': data.recentAttendanceRecords
          .map((r) => AttendanceRecordModel.fromEntity(r).toJson())
          .toList(),
      'cachedAt': DateTime.now().toIso8601String(),
    };
    await localDataSource.cacheDashboardJson(json);
  }
}
