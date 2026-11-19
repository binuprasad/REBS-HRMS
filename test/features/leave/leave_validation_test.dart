import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rebs_hrms/core/error/failures.dart';
import 'package:rebs_hrms/features/leave/domain/entities/leave_balance.dart';
import 'package:rebs_hrms/features/leave/domain/entities/leave_request.dart';
import 'package:rebs_hrms/features/leave/domain/repositories/leave_repository.dart';
import 'package:rebs_hrms/features/leave/domain/usecases/submit_leave_request_usecase.dart';

class MockLeaveRepository extends Mock implements LeaveRepository {}

void main() {
  late MockLeaveRepository mockRepository;
  late SubmitLeaveRequestUseCase useCase;

  final testBalance = LeaveBalance(
    employeeId: 'EMP-001',
    casual: const LeaveTypeBalance(total: 12, used: 4, available: 8),
    sick: const LeaveTypeBalance(total: 10, used: 3, available: 7),
    totalAvailable: 15,
  );

  final existingApprovedRequest = LeaveRequest(
    id: 'LR-1001',
    employeeId: 'EMP-001',
    leaveType: LeaveType.casual,
    startDate: '2026-11-25',
    endDate: '2026-11-26',
    days: 2,
    reason: 'Family event attendance',
    status: LeaveStatus.approved,
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(LeaveType.casual);
    registerFallbackValue(DateTime(2026, 11, 29));
  });

  setUp(() {
    mockRepository = MockLeaveRepository();
    useCase = SubmitLeaveRequestUseCase(mockRepository);

    when(() => mockRepository.getLeaveBalance(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => testBalance);

    when(() => mockRepository.getLeaveRequests(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => [existingApprovedRequest]);
  });

  group('Leave Validation Rules (Section 4 & 7)', () {
    test('Overlapping leave dates are rejected (Section 7: Test 4)', () async {
      // Trying to request leave for 2026-11-26 to 2026-11-27 (overlaps existing 2026-11-25..26)
      expect(
        () => useCase.execute(
          leaveType: LeaveType.casual,
          startDate: DateTime(2026, 11, 26),
          endDate: DateTime(2026, 11, 27),
          reason: 'Personal function attending',
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          contains('overlap'),
        )),
      );
    });

    test('Start date before current company date is rejected', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      expect(
        () => useCase.execute(
          leaveType: LeaveType.casual,
          startDate: pastDate,
          endDate: DateTime.now(),
          reason: 'Attending to urgent medical matter',
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          contains('cannot be before the current company date'),
        )),
      );
    });

    test('End date before start date is rejected', () async {
      final futureStart = DateTime.now().add(const Duration(days: 5));
      final earlierEnd = futureStart.subtract(const Duration(days: 1));

      expect(
        () => useCase.execute(
          leaveType: LeaveType.casual,
          startDate: futureStart,
          endDate: earlierEnd,
          reason: 'Valid reason exceeding ten nonspace',
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          contains('cannot be before the start date'),
        )),
      );
    });

    test('Reason with less than 10 non-whitespace characters is rejected', () async {
      final futureStart = DateTime.now().add(const Duration(days: 5));
      final futureEnd = futureStart.add(const Duration(days: 1));

      expect(
        () => useCase.execute(
          leaveType: LeaveType.casual,
          startDate: futureStart,
          endDate: futureEnd,
          reason: 'Sick    ', // Only 4 non-whitespace chars
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          contains('at least 10 non-whitespace characters'),
        )),
      );
    });

    test('Requested days exceeding available balance is rejected', () async {
      final futureStart = DateTime.now().add(const Duration(days: 10));
      // 10 days requested, but available casual is only 8
      final futureEnd = futureStart.add(const Duration(days: 9));

      expect(
        () => useCase.execute(
          leaveType: LeaveType.casual,
          startDate: futureStart,
          endDate: futureEnd,
          reason: 'Long annual vacation trip to Europe',
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          contains('exceed available'),
        )),
      );
    });

    test('Valid leave application passes validation and delegates to repository', () async {
      final futureStart = DateTime.now().add(const Duration(days: 10));
      final futureEnd = futureStart.add(const Duration(days: 1));

      final created = LeaveRequest(
        id: 'LR-1002',
        employeeId: 'EMP-001',
        leaveType: LeaveType.casual,
        startDate: '2026-11-29',
        endDate: '2026-11-30',
        days: 2,
        reason: 'Attending sister wedding ceremony',
        status: LeaveStatus.pending,
        createdAt: DateTime.now(),
      );

      when(() => mockRepository.submitLeaveRequest(
            leaveType: any(named: 'leaveType'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => created);

      final result = await useCase.execute(
        leaveType: LeaveType.casual,
        startDate: futureStart,
        endDate: futureEnd,
        reason: 'Attending sister wedding ceremony',
      );

      expect(result.id, equals('LR-1002'));
      expect(result.status, equals(LeaveStatus.pending));
    });
  });
}
