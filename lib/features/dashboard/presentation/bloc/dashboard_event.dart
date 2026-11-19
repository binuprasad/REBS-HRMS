import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {
  final bool forceRefresh;

  const LoadDashboard({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class UpdateElapsedDuration extends DashboardEvent {
  const UpdateElapsedDuration();
}

class RefreshDashboardSilently extends DashboardEvent {
  const RefreshDashboardSilently();
}
