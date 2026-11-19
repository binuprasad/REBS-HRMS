import 'package:equatable/equatable.dart';
import '../../../../core/location/location_service.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class CheckInRequested extends AttendanceEvent {
  const CheckInRequested();
}

class CheckOutRequested extends AttendanceEvent {
  const CheckOutRequested();
}

class LoadAttendanceHistory extends AttendanceEvent {
  final String? month;
  final bool forceRefresh;

  const LoadAttendanceHistory({this.month, this.forceRefresh = false});

  @override
  List<Object?> get props => [month, forceRefresh];
}

class ChangeLocationSimulationMode extends AttendanceEvent {
  final LocationSimulationMode mode;

  const ChangeLocationSimulationMode(this.mode);

  @override
  List<Object?> get props => [mode];
}

class SetCustomLocationCoordinates extends AttendanceEvent {
  final double latitude;
  final double longitude;

  const SetCustomLocationCoordinates(this.latitude, this.longitude);

  @override
  List<Object?> get props => [latitude, longitude];
}

class SetOfficeCoordinatesEvent extends AttendanceEvent {
  final double latitude;
  final double longitude;
  final double radiusMeters;

  const SetOfficeCoordinatesEvent({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusMeters];
}
