import 'package:equatable/equatable.dart';
import '../../../domain/entities/attendance_result.dart';

abstract class SyncState extends Equatable {
  final int pendingCount;
  final bool isConnected;

  const SyncState({
    this.pendingCount = 0,
    this.isConnected = true,
  });

  @override
  List<Object?> get props => [pendingCount, isConnected];
}

class SyncIdle extends SyncState {
  const SyncIdle({
    super.pendingCount,
    super.isConnected,
  });
}

class SyncInProgress extends SyncState {
  const SyncInProgress({
    super.pendingCount,
    super.isConnected,
  });
}

class SyncSuccess extends SyncState {
  final SyncResult result;

  const SyncSuccess({
    required this.result,
    super.pendingCount,
    super.isConnected,
  });

  @override
  List<Object?> get props => [result, pendingCount, isConnected];
}

class SyncFailure extends SyncState {
  final String errorMessage;

  const SyncFailure({
    required this.errorMessage,
    super.pendingCount,
    super.isConnected,
  });

  @override
  List<Object?> get props => [errorMessage, pendingCount, isConnected];
}
