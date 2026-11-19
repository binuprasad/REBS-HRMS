import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_data.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {
  final String? message;
  const DashboardLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  final int liveElapsedSeconds;

  const DashboardLoaded({
    required this.data,
    this.liveElapsedSeconds = 0,
  });

  DashboardLoaded copyWith({
    DashboardData? data,
    int? liveElapsedSeconds,
  }) {
    return DashboardLoaded(
      data: data ?? this.data,
      liveElapsedSeconds: liveElapsedSeconds ?? this.liveElapsedSeconds,
    );
  }

  String get formattedLiveDuration {
    if (liveElapsedSeconds <= 0) return '00:00:00';
    final hours = liveElapsedSeconds ~/ 3600;
    final minutes = (liveElapsedSeconds % 3600) ~/ 60;
    final seconds = liveElapsedSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [data, liveElapsedSeconds];
}

class DashboardEmpty extends DashboardState {
  final String message;

  const DashboardEmpty({required this.message});

  @override
  List<Object?> get props => [message];
}

class DashboardError extends DashboardState {
  final String message;
  final bool isOffline;

  const DashboardError({
    required this.message,
    this.isOffline = false,
  });

  @override
  List<Object?> get props => [message, isOffline];
}
