import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:rebs_hrms/core/constants/app_constants.dart';
import 'package:rebs_hrms/core/error/exceptions.dart';
import 'package:rebs_hrms/core/error/failures.dart';
import 'package:rebs_hrms/core/network/network_info.dart';
import 'package:rebs_hrms/core/utils/date_time_utils.dart';
import '../../domain/entities/attendance_event.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_result.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_local_data_source.dart';
import '../datasources/attendance_remote_data_source.dart';
import '../models/attendance_event_model.dart';
import '../models/attendance_record_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;
  final AttendanceLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final Uuid _uuid;

  AttendanceRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  @override
  Stream<int> get pendingEventsCountStream => localDataSource.pendingCountStream;

  @override
  Future<AttendanceResult> checkIn({
    required double latitude,
    required double longitude,
  }) async {
    final now = DateTime.now();
    final todayStr = DateTimeUtils.toDateString(now);

    // Rule: An employee can check in once per working day
    final existingRecord = await localDataSource.getAttendanceRecordByDate(todayStr);
    if (existingRecord != null && existingRecord.checkInTime != null) {
      throw const ConflictFailure('Employee has already checked in for today.');
    }

    final clientEventId = _uuid.v4();
    final eventModel = AttendanceEventModel(
      clientEventId: clientEventId,
      employeeId: AppConstants.defaultEmployeeId,
      type: AttendanceEventType.checkIn,
      timestamp: now,
      latitude: latitude,
      longitude: longitude,
      syncStatus: SyncStatus.pendingSync,
    );

    final recordModel = AttendanceRecordModel(
      date: todayStr,
      status: 'CHECKED_IN',
      checkInTime: now,
      checkInLatitude: latitude,
      checkInLongitude: longitude,
      durationMinutes: 0,
    );

    // Persist locally first (offline-first & crash resilient)
    await localDataSource.saveEvent(eventModel);
    await localDataSource.saveAttendanceRecord(recordModel);

    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return AttendanceResult(
        success: true,
        event: eventModel,
        record: recordModel,
        message: 'Checked in locally. Saved to offline sync queue.',
        isOffline: true,
      );
    }

    // Attempt online sync
    try {
      final responseData = await remoteDataSource.submitAttendanceEvent(eventModel);
      final serverEventId = responseData['event']?['eventId'] as String?;

      final syncedEvent = AttendanceEventModel(
        clientEventId: clientEventId,
        serverEventId: serverEventId,
        employeeId: AppConstants.defaultEmployeeId,
        type: AttendanceEventType.checkIn,
        timestamp: now,
        latitude: latitude,
        longitude: longitude,
        syncStatus: SyncStatus.synced,
        syncedAt: DateTime.now(),
      );

      await localDataSource.updateEvent(syncedEvent);

      return AttendanceResult(
        success: true,
        event: syncedEvent,
        record: recordModel,
        message: 'Check-in recorded and synchronized successfully.',
        isOffline: false,
      );
    } on ConflictException catch (e) {
      final rejectedEvent = AttendanceEventModel(
        clientEventId: clientEventId,
        employeeId: AppConstants.defaultEmployeeId,
        type: AttendanceEventType.checkIn,
        timestamp: now,
        latitude: latitude,
        longitude: longitude,
        syncStatus: SyncStatus.rejected,
        rejectionReason: e.message,
      );
      await localDataSource.updateEvent(rejectedEvent);
      throw ConflictFailure(e.message);
    } on ValidationException catch (e) {
      final rejectedEvent = AttendanceEventModel(
        clientEventId: clientEventId,
        employeeId: AppConstants.defaultEmployeeId,
        type: AttendanceEventType.checkIn,
        timestamp: now,
        latitude: latitude,
        longitude: longitude,
        syncStatus: SyncStatus.rejected,
        rejectionReason: e.message,
      );
      await localDataSource.updateEvent(rejectedEvent);
      throw ValidationFailure(e.message);
    } catch (_) {
      // On network timeout or server error, event remains in pending sync queue
      return AttendanceResult(
        success: true,
        event: eventModel,
        record: recordModel,
        message: 'Checked in locally (Server unreachable). Queued for sync.',
        isOffline: true,
      );
    }
  }

  @override
  Future<AttendanceResult> checkOut({
    required double latitude,
    required double longitude,
  }) async {
    final now = DateTime.now();
    final todayStr = DateTimeUtils.toDateString(now);

    // Rule: Check-out is permitted only after check-in
    final dayRecord = await localDataSource.getAttendanceRecordByDate(todayStr);
    if (dayRecord == null || dayRecord.checkInTime == null) {
      throw const ValidationFailure('Check-out is permitted only after check-in has been completed.');
    }

    if (dayRecord.checkOutTime != null) {
      throw const ConflictFailure('Employee has already checked out for today.');
    }

    final durationMinutes = now.difference(dayRecord.checkInTime!).inMinutes;
    final clientEventId = _uuid.v4();

    final eventModel = AttendanceEventModel(
      clientEventId: clientEventId,
      employeeId: AppConstants.defaultEmployeeId,
      type: AttendanceEventType.checkOut,
      timestamp: now,
      latitude: latitude,
      longitude: longitude,
      syncStatus: SyncStatus.pendingSync,
    );

    final updatedRecord = AttendanceRecordModel(
      date: todayStr,
      status: 'CHECKED_OUT',
      checkInTime: dayRecord.checkInTime,
      checkInLatitude: dayRecord.checkInLatitude,
      checkInLongitude: dayRecord.checkInLongitude,
      checkOutTime: now,
      checkOutLatitude: latitude,
      checkOutLongitude: longitude,
      durationMinutes: durationMinutes > 0 ? durationMinutes : 0,
    );

    // Persist locally first
    await localDataSource.saveEvent(eventModel);
    await localDataSource.saveAttendanceRecord(updatedRecord);

    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return AttendanceResult(
        success: true,
        event: eventModel,
        record: updatedRecord,
        message: 'Checked out locally. Saved to offline sync queue.',
        isOffline: true,
      );
    }

    // Attempt online sync
    try {
      final responseData = await remoteDataSource.submitAttendanceEvent(eventModel);
      final serverEventId = responseData['event']?['eventId'] as String?;

      final syncedEvent = AttendanceEventModel(
        clientEventId: clientEventId,
        serverEventId: serverEventId,
        employeeId: AppConstants.defaultEmployeeId,
        type: AttendanceEventType.checkOut,
        timestamp: now,
        latitude: latitude,
        longitude: longitude,
        syncStatus: SyncStatus.synced,
        syncedAt: DateTime.now(),
      );

      await localDataSource.updateEvent(syncedEvent);

      return AttendanceResult(
        success: true,
        event: syncedEvent,
        record: updatedRecord,
        message: 'Check-out recorded and synchronized successfully.',
        isOffline: false,
      );
    } on ConflictException catch (e) {
      final rejectedEvent = AttendanceEventModel(
        clientEventId: clientEventId,
        employeeId: AppConstants.defaultEmployeeId,
        type: AttendanceEventType.checkOut,
        timestamp: now,
        latitude: latitude,
        longitude: longitude,
        syncStatus: SyncStatus.rejected,
        rejectionReason: e.message,
      );
      await localDataSource.updateEvent(rejectedEvent);
      throw ConflictFailure(e.message);
    } on ValidationException catch (e) {
      final rejectedEvent = AttendanceEventModel(
        clientEventId: clientEventId,
        employeeId: AppConstants.defaultEmployeeId,
        type: AttendanceEventType.checkOut,
        timestamp: now,
        latitude: latitude,
        longitude: longitude,
        syncStatus: SyncStatus.rejected,
        rejectionReason: e.message,
      );
      await localDataSource.updateEvent(rejectedEvent);
      throw ValidationFailure(e.message);
    } catch (_) {
      return AttendanceResult(
        success: true,
        event: eventModel,
        record: updatedRecord,
        message: 'Checked out locally (Server unreachable). Queued for sync.',
        isOffline: true,
      );
    }
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceHistory({
    String? month,
    bool forceRefresh = false,
  }) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        final remoteRecords = await remoteDataSource.getAttendanceHistory(month: month);
        await localDataSource.cacheAttendanceRecords(remoteRecords);
        return remoteRecords;
      } catch (_) {
        return await localDataSource.getCachedAttendanceRecords(month: month);
      }
    } else {
      return await localDataSource.getCachedAttendanceRecords(month: month);
    }
  }

  @override
  Future<AttendanceRecord?> getTodayAttendanceRecord() async {
    final todayStr = DateTimeUtils.toDateString(DateTime.now());
    return await localDataSource.getAttendanceRecordByDate(todayStr);
  }

  @override
  Future<List<AttendanceEvent>> getPendingSyncEvents() async {
    return await localDataSource.getPendingEvents();
  }

  @override
  Future<List<AttendanceEvent>> getAllStoredEvents() async {
    return await localDataSource.getAllEvents();
  }

  @override
  Future<SyncResult> syncPendingEvents() async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const SyncResult(
        syncedCount: 0,
        rejectedCount: 0,
        totalProcessed: 0,
        errors: ['Device is offline. Connect to internet to sync.'],
      );
    }

    final pending = await localDataSource.getPendingEvents();
    if (pending.isEmpty) {
      return const SyncResult(
        syncedCount: 0,
        rejectedCount: 0,
        totalProcessed: 0,
      );
    }

    int synced = 0;
    int rejected = 0;
    final errors = <String>[];

    // Strictly process in FIFO chronological order
    for (final event in pending) {
      try {
        final response = await remoteDataSource.submitAttendanceEvent(event);
        final serverEventId = response['event']?['eventId'] as String?;

        final syncedEvent = AttendanceEventModel(
          clientEventId: event.clientEventId,
          serverEventId: serverEventId,
          employeeId: event.employeeId,
          type: event.type,
          timestamp: event.timestamp,
          latitude: event.latitude,
          longitude: event.longitude,
          syncStatus: SyncStatus.synced,
          syncedAt: DateTime.now(),
        );

        await localDataSource.updateEvent(syncedEvent);
        synced++;
      } on ConflictException catch (e) {
        // 409 Conflict: Attendance already recorded on server
        final rejectedEvent = AttendanceEventModel(
          clientEventId: event.clientEventId,
          employeeId: event.employeeId,
          type: event.type,
          timestamp: event.timestamp,
          latitude: event.latitude,
          longitude: event.longitude,
          syncStatus: SyncStatus.rejected,
          rejectionReason: e.message,
        );
        await localDataSource.updateEvent(rejectedEvent);
        rejected++;
        errors.add('${event.type.displayName}: ${e.message}');
      } on ValidationException catch (e) {
        // 422 Validation error
        final rejectedEvent = AttendanceEventModel(
          clientEventId: event.clientEventId,
          employeeId: event.employeeId,
          type: event.type,
          timestamp: event.timestamp,
          latitude: event.latitude,
          longitude: event.longitude,
          syncStatus: SyncStatus.rejected,
          rejectionReason: e.message,
        );
        await localDataSource.updateEvent(rejectedEvent);
        rejected++;
        errors.add('${event.type.displayName}: ${e.message}');
      } catch (e) {
        // Network timeout / connection lost: halt the queue to preserve FIFO ordering!
        errors.add('Sync paused: connection interrupted while processing ${event.clientEventId}.');
        break;
      }
    }

    // Refresh history from remote after sync
    try {
      final freshRecords = await remoteDataSource.getAttendanceHistory();
      await localDataSource.cacheAttendanceRecords(freshRecords);
    } catch (_) {}

    return SyncResult(
      syncedCount: synced,
      rejectedCount: rejected,
      totalProcessed: synced + rejected,
      errors: errors,
    );
  }
}
