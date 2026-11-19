import 'package:rebs_hrms/core/constants/app_constants.dart';
import 'package:rebs_hrms/core/error/exceptions.dart';
import 'package:rebs_hrms/core/error/failures.dart';
import 'package:rebs_hrms/core/network/network_info.dart';
import 'package:rebs_hrms/core/utils/date_time_utils.dart';
import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/repositories/leave_repository.dart';
import '../datasources/leave_local_data_source.dart';
import '../datasources/leave_remote_data_source.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  final LeaveRemoteDataSource remoteDataSource;
  final LeaveLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  LeaveRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<LeaveBalance> getLeaveBalance({bool forceRefresh = false}) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        final balance = await remoteDataSource.getLeaveBalance();
        await localDataSource.cacheLeaveBalance(balance);
        return balance;
      } catch (_) {
        final cached = await localDataSource.getCachedLeaveBalance();
        if (cached != null) return cached;
        rethrow;
      }
    } else {
      final cached = await localDataSource.getCachedLeaveBalance();
      if (cached != null) return cached;
      throw const NetworkFailure('No cached leave balance available offline.');
    }
  }

  @override
  Future<List<LeaveRequest>> getLeaveRequests({bool forceRefresh = false}) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        final requests = await remoteDataSource.getLeaveRequests();
        await localDataSource.cacheLeaveRequests(requests);
        return requests;
      } catch (_) {
        return await localDataSource.getCachedLeaveRequests();
      }
    } else {
      return await localDataSource.getCachedLeaveRequests();
    }
  }

  @override
  Future<LeaveRequest> submitLeaveRequest({
    required LeaveType leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      throw const NetworkFailure(
        'Leave submission requires an active network connection. Cannot submit while offline.',
      );
    }

    final payload = {
      'employeeId': AppConstants.defaultEmployeeId,
      'leaveType': leaveType.value,
      'startDate': DateTimeUtils.toDateString(startDate),
      'endDate': DateTimeUtils.toDateString(endDate),
      'reason': reason,
    };

    try {
      final created = await remoteDataSource.submitLeaveRequest(payload);
      await localDataSource.addLeaveRequest(created);

      // Refresh balance in background
      try {
        final freshBalance = await remoteDataSource.getLeaveBalance();
        await localDataSource.cacheLeaveBalance(freshBalance);
      } catch (_) {}

      return created;
    } on ValidationException catch (e) {
      throw ValidationFailure(e.message);
    } on ConflictException catch (e) {
      throw ConflictFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.statusCode);
    } catch (e) {
      throw ServerFailure('Failed to submit leave request: ${e.toString()}');
    }
  }
}
