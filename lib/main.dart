import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rebs_hrms/core/di/service_locator.dart';
import 'package:rebs_hrms/core/storage/hive_service.dart';
import 'package:rebs_hrms/core/theme/app_theme.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/sync/sync_bloc.dart';
import 'package:rebs_hrms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:rebs_hrms/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:rebs_hrms/features/home/presentation/screens/main_navigation_shell.dart';
import 'package:rebs_hrms/features/leave/presentation/bloc/leave_bloc.dart';
import 'package:rebs_hrms/features/leave/presentation/bloc/leave_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive storage and open boxes
  await HiveService.init();

  // Initialize GetIt Dependency Injection
  await initServiceLocator();

  runApp(const RebsHrmsApp());
}

class RebsHrmsApp extends StatelessWidget {
  const RebsHrmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DashboardBloc>(
          create: (_) => sl<DashboardBloc>()..add(const LoadDashboard()),
        ),
        BlocProvider<AttendanceBloc>(
          create: (_) => sl<AttendanceBloc>()..add(const LoadAttendanceHistory()),
        ),
        BlocProvider<SyncBloc>(
          create: (_) => sl<SyncBloc>(),
        ),
        BlocProvider<LeaveBloc>(
          create: (_) => sl<LeaveBloc>()..add(const LoadLeaveData()),
        ),
      ],
      child: MaterialApp(
        title: 'REBS HRMS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigationShell(),
      ),
    );
  }
}
