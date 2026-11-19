import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/network/network_info.dart';
import '../../../domain/usecases/sync_attendance_events_usecase.dart';
import '../../../domain/usecases/get_pending_events_usecase.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncAttendanceEventsUseCase syncAttendanceEventsUseCase;
  final GetPendingEventsUseCase getPendingEventsUseCase;
  final NetworkInfo networkInfo;

  StreamSubscription<int>? _pendingSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _wasConnected = true;

  SyncBloc({
    required this.syncAttendanceEventsUseCase,
    required this.getPendingEventsUseCase,
    required this.networkInfo,
  }) : super(const SyncIdle()) {
    on<SyncNowRequested>(_onSyncNowRequested);
    on<PendingCountUpdated>(_onPendingCountUpdated);
    on<ConnectivityStatusChanged>(_onConnectivityStatusChanged);

    _initSubscriptions();
  }

  void _initSubscriptions() {
    _pendingSubscription = getPendingEventsUseCase.watchCount().listen((count) {
      add(PendingCountUpdated(count));
    });

    _connectivitySubscription = networkInfo.onConnectivityChanged.listen((isConnected) {
      add(ConnectivityStatusChanged(isConnected));
    });

    // Check initial connectivity and pending count
    networkInfo.isConnected.then((connected) {
      _wasConnected = connected;
      add(ConnectivityStatusChanged(connected));
    });

    getPendingEventsUseCase.execute().then((events) {
      add(PendingCountUpdated(events.length));
    });
  }

  void _onPendingCountUpdated(
    PendingCountUpdated event,
    Emitter<SyncState> emit,
  ) {
    if (state is SyncInProgress) {
      emit(SyncInProgress(
        pendingCount: event.count,
        isConnected: state.isConnected,
      ));
    } else {
      emit(SyncIdle(
        pendingCount: event.count,
        isConnected: state.isConnected,
      ));
    }
  }

  Future<void> _onConnectivityStatusChanged(
    ConnectivityStatusChanged event,
    Emitter<SyncState> emit,
  ) async {
    final nowConnected = event.isConnected;
    final transitionedToOnline = !_wasConnected && nowConnected;
    _wasConnected = nowConnected;

    emit(SyncIdle(
      pendingCount: state.pendingCount,
      isConnected: nowConnected,
    ));

    // Automatically trigger sync when connectivity is restored and items are pending
    if (transitionedToOnline && state.pendingCount > 0) {
      add(const SyncNowRequested());
    }
  }

  Future<void> _onSyncNowRequested(
    SyncNowRequested event,
    Emitter<SyncState> emit,
  ) async {
    if (state is SyncInProgress) return;

    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      emit(SyncFailure(
        errorMessage: 'Cannot sync while device is offline.',
        pendingCount: state.pendingCount,
        isConnected: false,
      ));
      emit(SyncIdle(
        pendingCount: state.pendingCount,
        isConnected: false,
      ));
      return;
    }

    emit(SyncInProgress(
      pendingCount: state.pendingCount,
      isConnected: true,
    ));

    try {
      final result = await syncAttendanceEventsUseCase.execute();
      final remaining = await getPendingEventsUseCase.execute();

      emit(SyncSuccess(
        result: result,
        pendingCount: remaining.length,
        isConnected: true,
      ));

      // Return to Idle
      emit(SyncIdle(
        pendingCount: remaining.length,
        isConnected: true,
      ));
    } catch (e) {
      emit(SyncFailure(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
        pendingCount: state.pendingCount,
        isConnected: true,
      ));
      emit(SyncIdle(
        pendingCount: state.pendingCount,
        isConnected: true,
      ));
    }
  }

  @override
  Future<void> close() {
    _pendingSubscription?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
