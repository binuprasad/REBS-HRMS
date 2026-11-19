import 'package:equatable/equatable.dart';
import '../../../../core/location/location_service.dart';
import '../../domain/entities/attendance_record.dart';

class AttendanceState extends Equatable {
  final bool isActionInProgress; // Prevents double-taps
  final bool isHistoryLoading;
  final List<AttendanceRecord> history;
  final AttendanceRecord? todayRecord;
  final LocationSimulationMode simulationMode;
  final LocationResult? lastLocationResult;
  final String? actionSuccessMessage;
  final String? errorMessage;
  final bool isLocationPermissionPermanentlyDenied;
  final bool isLocationServiceDisabled;
  final bool isOutsideGeofence;
  final double? distanceMeters;

  const AttendanceState({
    this.isActionInProgress = false,
    this.isHistoryLoading = false,
    this.history = const [],
    this.todayRecord,
    this.simulationMode = LocationSimulationMode.atOffice,
    this.lastLocationResult,
    this.actionSuccessMessage,
    this.errorMessage,
    this.isLocationPermissionPermanentlyDenied = false,
    this.isLocationServiceDisabled = false,
    this.isOutsideGeofence = false,
    this.distanceMeters,
  });

  AttendanceState copyWith({
    bool? isActionInProgress,
    bool? isHistoryLoading,
    List<AttendanceRecord>? history,
    AttendanceRecord? todayRecord,
    LocationSimulationMode? simulationMode,
    LocationResult? lastLocationResult,
    String? actionSuccessMessage,
    String? errorMessage,
    bool? isLocationPermissionPermanentlyDenied,
    bool? isLocationServiceDisabled,
    bool? isOutsideGeofence,
    double? distanceMeters,
    bool clearMessages = false,
  }) {
    return AttendanceState(
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
      history: history ?? this.history,
      todayRecord: todayRecord ?? this.todayRecord,
      simulationMode: simulationMode ?? this.simulationMode,
      lastLocationResult: lastLocationResult ?? this.lastLocationResult,
      actionSuccessMessage: clearMessages ? null : (actionSuccessMessage ?? this.actionSuccessMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      isLocationPermissionPermanentlyDenied:
          isLocationPermissionPermanentlyDenied ?? this.isLocationPermissionPermanentlyDenied,
      isLocationServiceDisabled:
          isLocationServiceDisabled ?? this.isLocationServiceDisabled,
      isOutsideGeofence: isOutsideGeofence ?? this.isOutsideGeofence,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }

  @override
  List<Object?> get props => [
        isActionInProgress,
        isHistoryLoading,
        history,
        todayRecord,
        simulationMode,
        lastLocationResult,
        actionSuccessMessage,
        errorMessage,
        isLocationPermissionPermanentlyDenied,
        isLocationServiceDisabled,
        isOutsideGeofence,
        distanceMeters,
      ];
}
