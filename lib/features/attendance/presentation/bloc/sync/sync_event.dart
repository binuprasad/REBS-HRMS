import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class SyncNowRequested extends SyncEvent {
  const SyncNowRequested();
}

class PendingCountUpdated extends SyncEvent {
  final int count;

  const PendingCountUpdated(this.count);

  @override
  List<Object?> get props => [count];
}

class ConnectivityStatusChanged extends SyncEvent {
  final bool isConnected;

  const ConnectivityStatusChanged(this.isConnected);

  @override
  List<Object?> get props => [isConnected];
}
