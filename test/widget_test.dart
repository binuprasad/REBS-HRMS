import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebs_hrms/core/widgets/offline_banner.dart';
import 'package:rebs_hrms/core/widgets/sync_indicator_button.dart';
import 'package:rebs_hrms/features/attendance/domain/entities/attendance_record.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/sync/sync_bloc.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/sync/sync_event.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/sync/sync_state.dart';
import 'package:rebs_hrms/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:rebs_hrms/features/dashboard/domain/entities/employee.dart';
import 'package:rebs_hrms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:rebs_hrms/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:rebs_hrms/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:rebs_hrms/features/dashboard/presentation/screens/dashboard_screen.dart';

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState> implements DashboardBloc {}
class MockAttendanceBloc extends MockBloc<AttendanceEvent, AttendanceState> implements AttendanceBloc {}
class MockSyncBloc extends MockBloc<SyncEvent, SyncState> implements SyncBloc {}

void main() {
  late MockDashboardBloc mockDashboardBloc;
  late MockAttendanceBloc mockAttendanceBloc;
  late MockSyncBloc mockSyncBloc;

  final testEmployee = Employee(
    id: 'EMP-001',
    name: 'Alex Morgan',
    email: 'alex.morgan@rebs.io',
    department: 'Mobile Engineering',
    role: 'Senior Flutter Engineer',
    officeConfig: const OfficeConfig(
      name: 'REBS HQ',
      latitude: 12.971598,
      longitude: 77.594566,
      geofenceRadiusMeters: 200,
      companyTimezone: 'Asia/Kolkata',
      workStartTime: '09:00',
      workEndTime: '18:00',
    ),
  );

  setUp(() {
    mockDashboardBloc = MockDashboardBloc();
    mockAttendanceBloc = MockAttendanceBloc();
    mockSyncBloc = MockSyncBloc();
  });

  group('Widget Tests (Section 7)', () {
    testWidgets('1. OfflineBanner renders offline message and triggers retry action', (WidgetTester tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              message: 'Viewing cached dashboard data while offline.',
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Viewing cached dashboard data while offline.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryPressed, isTrue);
    });

    testWidgets('2. Dashboard & Sync indicator screen renders offline state and Pending Sync count', (WidgetTester tester) async {
      // Set up offline loaded dashboard state with pending items
      final offlineData = DashboardData(
        employee: testEmployee,
        todayStatus: TodayAttendanceStatus.notCheckedIn,
        recentAttendanceRecords: const [],
        isOffline: true,
      );

      whenListen(
        mockDashboardBloc,
        Stream<DashboardState>.fromIterable([DashboardLoaded(data: offlineData)]),
        initialState: DashboardLoaded(data: offlineData),
      );

      whenListen(
        mockAttendanceBloc,
        Stream<AttendanceState>.fromIterable([const AttendanceState()]),
        initialState: const AttendanceState(),
      );

      // Simulate 2 pending offline events with disconnected state
      whenListen(
        mockSyncBloc,
        Stream<SyncState>.fromIterable([const SyncIdle(pendingCount: 2, isConnected: false)]),
        initialState: const SyncIdle(pendingCount: 2, isConnected: false),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
              BlocProvider<AttendanceBloc>.value(value: mockAttendanceBloc),
              BlocProvider<SyncBloc>.value(value: mockSyncBloc),
            ],
            child: Scaffold(
              appBar: AppBar(
                title: const Text('REBS HRMS'),
                actions: const [
                  SyncIndicatorButton(),
                ],
              ),
              body: DashboardScreen(
                onNavigateToAttendance: () {},
                onNavigateToLeave: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the OfflineBanner is prominently displayed
      expect(find.text('Viewing cached dashboard data while offline.'), findsOneWidget);

      // Verify employee name and department appear on Dashboard
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.text('EMP-001'), findsOneWidget);

      // Verify Today's attendance status is displayed
      expect(find.text("Today's Attendance"), findsOneWidget);
      expect(find.text('Not Checked In'), findsWidgets);

      // Verify Pending Sync Indicator pill in AppBar shows "2 offline"
      expect(find.text('2 offline'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsWidgets);
    });

    testWidgets('3. SyncIndicatorButton shows syncing state when sync is in progress', (WidgetTester tester) async {
      whenListen(
        mockSyncBloc,
        Stream<SyncState>.fromIterable([const SyncInProgress(pendingCount: 2, isConnected: true)]),
        initialState: const SyncInProgress(pendingCount: 2, isConnected: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<SyncBloc>.value(
            value: mockSyncBloc,
            child: const Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Row(children: [SyncIndicatorButton()]),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify loading spinner and label are active
      expect(find.text('Syncing...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
