import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';
import 'package:rebs_hrms/core/error/failures.dart';
import 'package:rebs_hrms/core/network/network_info.dart';
import 'package:rebs_hrms/core/utils/date_time_utils.dart';
import 'package:rebs_hrms/features/attendance/data/datasources/attendance_local_data_source.dart';
import 'package:rebs_hrms/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:rebs_hrms/features/attendance/data/models/attendance_event_model.dart';
import 'package:rebs_hrms/features/attendance/data/models/attendance_record_model.dart';
import 'package:rebs_hrms/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:rebs_hrms/features/attendance/domain/entities/attendance_event.dart';
import 'package:rebs_hrms/features/attendance/domain/entities/sync_status.dart';

class MockRemoteDataSource extends Mock implements AttendanceRemoteDataSource {}
class MockLocalDataSource extends Mock implements AttendanceLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}
class MockUuid extends Mock implements Uuid {}

void main() {
  late MockRemoteDataSource mockRemote;
  late MockLocalDataSource mockLocal;
  late MockNetworkInfo mockNetwork;
  late AttendanceRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(AttendanceEventModel(
      clientEventId: 'fallback-uuid',
      employeeId: 'EMP-001',
      type: AttendanceEventType.checkIn,
      timestamp: DateTime.now(),
      latitude: 12.971598,
      longitude: 77.594566,
    ));
    registerFallbackValue(const AttendanceRecordModel(
      date: '2026-11-19',
      status: 'PRESENT',
    ));
  });

  setUp(() {
    mockRemote = MockRemoteDataSource();
    mockLocal = MockLocalDataSource();
    mockNetwork = MockNetworkInfo();

    repository = AttendanceRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
      networkInfo: mockNetwork,
    );

    when(() => mockLocal.pendingCountStream).thenAnswer((_) => Stream.value(0));
    when(() => mockLocal.saveEvent(any())).thenAnswer((_) async {});
    when(() => mockLocal.updateEvent(any())).thenAnswer((_) async {});
    when(() => mockLocal.saveAttendanceRecord(any())).thenAnswer((_) async {});
  });

  group('Required Automated Tests (Section 7)', () {
    test('1. Check-out without check-in is rejected', () async {
      final todayStr = DateTimeUtils.toDateString(DateTime.now());

      // Simulate no check-in record exists for today
      when(() => mockLocal.getAttendanceRecordByDate(todayStr))
          .thenAnswer((_) async => null);

      expect(
        () => repository.checkOut(latitude: 12.971598, longitude: 77.594566),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          contains('Check-out is permitted only after check-in'),
        )),
      );

      // Verify that no check-out event was saved
      verifyNever(() => mockLocal.saveEvent(any()));
    });

    test('2. Repeated submission or retry does not create duplicate attendance', () async {
      final now = DateTime.now();
      final todayStr = DateTimeUtils.toDateString(now);

      // Simulate existing check-in already recorded for today
      final existingRecord = AttendanceRecordModel(
        date: todayStr,
        status: 'CHECKED_IN',
        checkInTime: now.subtract(const Duration(hours: 1)),
        checkInLatitude: 12.971598,
        checkInLongitude: 77.594566,
      );

      when(() => mockLocal.getAttendanceRecordByDate(todayStr))
          .thenAnswer((_) async => existingRecord);

      // Second check-in attempt on the same day must be rejected with ConflictFailure
      expect(
        () => repository.checkIn(latitude: 12.971598, longitude: 77.594566),
        throwsA(isA<ConflictFailure>().having(
          (f) => f.message,
          'message',
          contains('already checked in for today'),
        )),
      );

      // Verify no duplicate record or event was saved
      verifyNever(() => mockLocal.saveEvent(any()));
    });

    test('3. Pending attendance survives persistence and can be synchronized in order (FIFO)', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);

      final checkInTime = DateTime(2026, 11, 19, 9, 0, 0);
      final checkOutTime = DateTime(2026, 11, 19, 18, 0, 0);

      final pendingCheckIn = AttendanceEventModel(
        clientEventId: 'uuid-pending-in',
        employeeId: 'EMP-001',
        type: AttendanceEventType.checkIn,
        timestamp: checkInTime,
        latitude: 12.971598,
        longitude: 77.594566,
        syncStatus: SyncStatus.pendingSync,
      );

      final pendingCheckOut = AttendanceEventModel(
        clientEventId: 'uuid-pending-out',
        employeeId: 'EMP-001',
        type: AttendanceEventType.checkOut,
        timestamp: checkOutTime,
        latitude: 12.971598,
        longitude: 77.594566,
        syncStatus: SyncStatus.pendingSync,
      );

      // Return pending events in chronological order
      when(() => mockLocal.getPendingEvents())
          .thenAnswer((_) async => [pendingCheckIn, pendingCheckOut]);

      final callOrder = <String>[];

      when(() => mockRemote.submitAttendanceEvent(any()))
          .thenAnswer((invocation) async {
        final event = invocation.positionalArguments[0] as AttendanceEventModel;
        callOrder.add(event.type.value);
        return {
          'success': true,
          'event': {'eventId': 'srv-${event.clientEventId}'},
        };
      });

      when(() => mockRemote.getAttendanceHistory(month: any(named: 'month')))
          .thenAnswer((_) async => []);
      when(() => mockLocal.cacheAttendanceRecords(any()))
          .thenAnswer((_) async {});

      final syncResult = await repository.syncPendingEvents();

      // Verify both events succeeded
      expect(syncResult.syncedCount, equals(2));
      expect(syncResult.rejectedCount, equals(0));
      expect(syncResult.hasFailures, isFalse);

      // Strict FIFO ordering: CHECK_IN was submitted BEFORE CHECK_OUT!
      expect(callOrder, equals(['CHECK_IN', 'CHECK_OUT']));

      // Verify that localDataSource updated both events to Synced
      verify(() => mockLocal.updateEvent(any(that: isA<AttendanceEventModel>().having(
            (e) => e.syncStatus,
            'syncStatus',
            equals(SyncStatus.synced),
          )))).called(2);
    });
  });
}
