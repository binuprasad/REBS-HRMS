import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import '../location/location_service.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../storage/hive_service.dart';

// Dashboard
import '../../features/dashboard/data/datasources/dashboard_local_data_source.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_data_usecase.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';

// Attendance
import '../../features/attendance/data/datasources/attendance_local_data_source.dart';
import '../../features/attendance/data/datasources/attendance_remote_data_source.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/domain/usecases/check_in_usecase.dart';
import '../../features/attendance/domain/usecases/check_out_usecase.dart';
import '../../features/attendance/domain/usecases/get_attendance_history_usecase.dart';
import '../../features/attendance/domain/usecases/get_pending_events_usecase.dart';
import '../../features/attendance/domain/usecases/sync_attendance_events_usecase.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/attendance/presentation/bloc/sync/sync_bloc.dart';

// Leave
import '../../features/leave/data/datasources/leave_local_data_source.dart';
import '../../features/leave/data/datasources/leave_remote_data_source.dart';
import '../../features/leave/data/repositories/leave_repository_impl.dart';
import '../../features/leave/domain/repositories/leave_repository.dart';
import '../../features/leave/domain/usecases/get_leave_balance_usecase.dart';
import '../../features/leave/domain/usecases/get_leave_requests_usecase.dart';
import '../../features/leave/domain/usecases/submit_leave_request_usecase.dart';
import '../../features/leave/presentation/bloc/leave_bloc.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // 1. External & Core
  sl.registerLazySingleton<Uuid>(() => const Uuid());
  sl.registerLazySingleton<HiveService>(() => HiveService());
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<LocationService>(() => LocationServiceImpl(hiveService: sl()));

  // 2. Dashboard Feature
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<DashboardLocalDataSource>(
    () => DashboardLocalDataSourceImpl(hiveService: sl()),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<GetDashboardDataUseCase>(
    () => GetDashboardDataUseCase(sl()),
  );
  sl.registerFactory<DashboardBloc>(
    () => DashboardBloc(getDashboardDataUseCase: sl()),
  );

  // 3. Attendance & Sync Feature
  sl.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<AttendanceLocalDataSource>(
    () => AttendanceLocalDataSourceImpl(hiveService: sl()),
  );
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      uuid: sl(),
    ),
  );
  sl.registerLazySingleton<CheckInUseCase>(() => CheckInUseCase(sl()));
  sl.registerLazySingleton<CheckOutUseCase>(() => CheckOutUseCase(sl()));
  sl.registerLazySingleton<GetAttendanceHistoryUseCase>(
    () => GetAttendanceHistoryUseCase(sl()),
  );
  sl.registerLazySingleton<SyncAttendanceEventsUseCase>(
    () => SyncAttendanceEventsUseCase(sl()),
  );
  sl.registerLazySingleton<GetPendingEventsUseCase>(
    () => GetPendingEventsUseCase(sl()),
  );

  sl.registerFactory<AttendanceBloc>(
    () => AttendanceBloc(
      checkInUseCase: sl(),
      checkOutUseCase: sl(),
      getAttendanceHistoryUseCase: sl(),
      attendanceRepository: sl(),
      locationService: sl(),
    ),
  );

  sl.registerLazySingleton<SyncBloc>(
    () => SyncBloc(
      syncAttendanceEventsUseCase: sl(),
      getPendingEventsUseCase: sl(),
      networkInfo: sl(),
    ),
  );

  // 4. Leave Feature
  sl.registerLazySingleton<LeaveRemoteDataSource>(
    () => LeaveRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<LeaveLocalDataSource>(
    () => LeaveLocalDataSourceImpl(hiveService: sl()),
  );
  sl.registerLazySingleton<LeaveRepository>(
    () => LeaveRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<GetLeaveBalanceUseCase>(
    () => GetLeaveBalanceUseCase(sl()),
  );
  sl.registerLazySingleton<GetLeaveRequestsUseCase>(
    () => GetLeaveRequestsUseCase(sl()),
  );
  sl.registerLazySingleton<SubmitLeaveRequestUseCase>(
    () => SubmitLeaveRequestUseCase(sl()),
  );

  sl.registerFactory<LeaveBloc>(
    () => LeaveBloc(
      getLeaveBalanceUseCase: sl(),
      getLeaveRequestsUseCase: sl(),
      submitLeaveRequestUseCase: sl(),
    ),
  );
}
