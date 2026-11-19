import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rebs_hrms/features/attendance/domain/entities/attendance_record.dart';
import '../../domain/usecases/get_dashboard_data_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardDataUseCase getDashboardDataUseCase;
  Timer? _tickerTimer;

  DashboardBloc({required this.getDashboardDataUseCase})
      : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<UpdateElapsedDuration>(_onUpdateElapsedDuration);
    on<RefreshDashboardSilently>(_onRefreshDashboardSilently);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    // Only emit loading if not already in loaded state with force refresh
    if (state is! DashboardLoaded || event.forceRefresh) {
      emit(const DashboardLoading(message: 'Loading dashboard data...'));
    }

    try {
      final data = await getDashboardDataUseCase.execute(forceRefresh: event.forceRefresh);

      final liveSeconds = _calculateSeconds(data.checkInTime, data.checkOutTime);
      emit(DashboardLoaded(data: data, liveElapsedSeconds: liveSeconds));

      _startOrStopTimer(data.todayStatus);
    } catch (e) {
      emit(DashboardError(
        message: e.toString().replaceFirst('Exception: ', '').replaceFirst('Failure: ', ''),
      ));
    }
  }

  void _onUpdateElapsedDuration(
    UpdateElapsedDuration event,
    Emitter<DashboardState> emit,
  ) {
    if (state is DashboardLoaded) {
      final current = state as DashboardLoaded;
      if (current.data.todayStatus == TodayAttendanceStatus.checkedIn &&
          current.data.checkInTime != null) {
        final seconds = DateTime.now().difference(current.data.checkInTime!).inSeconds;
        emit(current.copyWith(liveElapsedSeconds: seconds > 0 ? seconds : 0));
      }
    }
  }

  Future<void> _onRefreshDashboardSilently(
    RefreshDashboardSilently event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final data = await getDashboardDataUseCase.execute(forceRefresh: true);
      final liveSeconds = _calculateSeconds(data.checkInTime, data.checkOutTime);
      emit(DashboardLoaded(data: data, liveElapsedSeconds: liveSeconds));
      _startOrStopTimer(data.todayStatus);
    } catch (_) {
      // Keep existing state if silent refresh fails
    }
  }

  void _startOrStopTimer(TodayAttendanceStatus status) {
    _tickerTimer?.cancel();
    if (status == TodayAttendanceStatus.checkedIn) {
      _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        add(const UpdateElapsedDuration());
      });
    }
  }

  int _calculateSeconds(DateTime? inTime, DateTime? outTime) {
    if (inTime == null) return 0;
    if (outTime != null) {
      return outTime.difference(inTime).inSeconds;
    }
    final now = DateTime.now();
    final diff = now.difference(inTime).inSeconds;
    return diff > 0 ? diff : 0;
  }

  @override
  Future<void> close() {
    _tickerTimer?.cancel();
    return super.close();
  }
}
