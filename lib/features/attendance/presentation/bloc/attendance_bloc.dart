import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/location/location_service.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/usecases/check_in_usecase.dart';
import '../../domain/usecases/check_out_usecase.dart';
import '../../domain/usecases/get_attendance_history_usecase.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final CheckInUseCase checkInUseCase;
  final CheckOutUseCase checkOutUseCase;
  final GetAttendanceHistoryUseCase getAttendanceHistoryUseCase;
  final AttendanceRepository attendanceRepository;
  final LocationService locationService;

  AttendanceBloc({
    required this.checkInUseCase,
    required this.checkOutUseCase,
    required this.getAttendanceHistoryUseCase,
    required this.attendanceRepository,
    required this.locationService,
  }) : super(AttendanceState(simulationMode: locationService.simulationMode)) {
    on<CheckInRequested>(_onCheckInRequested);
    on<CheckOutRequested>(_onCheckOutRequested);
    on<LoadAttendanceHistory>(_onLoadAttendanceHistory);
    on<ChangeLocationSimulationMode>(_onChangeLocationSimulationMode);
    on<SetCustomLocationCoordinates>(_onSetCustomLocationCoordinates);
    on<SetOfficeCoordinatesEvent>(_onSetOfficeCoordinates);
  }

  Future<void> _onCheckInRequested(
    CheckInRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    // Prevent double-tap submissions
    if (state.isActionInProgress) return;

    emit(state.copyWith(
      isActionInProgress: true,
      clearMessages: true,
      isOutsideGeofence: false,
      isLocationPermissionPermanentlyDenied: false,
      isLocationServiceDisabled: false,
    ));

    try {
      final location = await locationService.getCurrentLocation();
      emit(state.copyWith(lastLocationResult: location));

      // Geofence check
      if (!location.isWithinGeofence) {
        emit(state.copyWith(
          isActionInProgress: false,
          isOutsideGeofence: true,
          distanceMeters: location.distanceToOfficeMeters,
          errorMessage:
              'Location outside permitted office perimeter (${location.distanceToOfficeMeters.round()}m away; allowed: ${locationService.geofenceRadiusMeters.round()}m).',
        ));
        return;
      }

      final result = await checkInUseCase.execute(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      final todayRecord = await attendanceRepository.getTodayAttendanceRecord();
      final history = await getAttendanceHistoryUseCase.execute();

      emit(state.copyWith(
        isActionInProgress: false,
        todayRecord: todayRecord,
        history: history,
        actionSuccessMessage: result.message,
      ));
    } on LocationException catch (e) {
      final isPermDenied = e.message.toLowerCase().contains('permanently denied');
      final isServiceOff = e.message.toLowerCase().contains('disabled');

      emit(state.copyWith(
        isActionInProgress: false,
        errorMessage: e.message,
        isLocationPermissionPermanentlyDenied: isPermDenied,
        isLocationServiceDisabled: isServiceOff,
      ));
    } on Failure catch (e) {
      emit(state.copyWith(
        isActionInProgress: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isActionInProgress: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onCheckOutRequested(
    CheckOutRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state.isActionInProgress) return;

    emit(state.copyWith(
      isActionInProgress: true,
      clearMessages: true,
      isOutsideGeofence: false,
      isLocationPermissionPermanentlyDenied: false,
      isLocationServiceDisabled: false,
    ));

    try {
      final location = await locationService.getCurrentLocation();
      emit(state.copyWith(lastLocationResult: location));

      if (!location.isWithinGeofence) {
        emit(state.copyWith(
          isActionInProgress: false,
          isOutsideGeofence: true,
          distanceMeters: location.distanceToOfficeMeters,
          errorMessage:
              'Location outside permitted office perimeter (${location.distanceToOfficeMeters.round()}m away; allowed: ${locationService.geofenceRadiusMeters.round()}m).',
        ));
        return;
      }

      final result = await checkOutUseCase.execute(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      final todayRecord = await attendanceRepository.getTodayAttendanceRecord();
      final history = await getAttendanceHistoryUseCase.execute();

      emit(state.copyWith(
        isActionInProgress: false,
        todayRecord: todayRecord,
        history: history,
        actionSuccessMessage: result.message,
      ));
    } on LocationException catch (e) {
      final isPermDenied = e.message.toLowerCase().contains('permanently denied');
      final isServiceOff = e.message.toLowerCase().contains('disabled');

      emit(state.copyWith(
        isActionInProgress: false,
        errorMessage: e.message,
        isLocationPermissionPermanentlyDenied: isPermDenied,
        isLocationServiceDisabled: isServiceOff,
      ));
    } on Failure catch (e) {
      emit(state.copyWith(
        isActionInProgress: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isActionInProgress: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onLoadAttendanceHistory(
    LoadAttendanceHistory event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isHistoryLoading: true));
    try {
      final records = await getAttendanceHistoryUseCase.execute(
        month: event.month,
        forceRefresh: event.forceRefresh,
      );
      final today = await attendanceRepository.getTodayAttendanceRecord();

      emit(state.copyWith(
        isHistoryLoading: false,
        history: records,
        todayRecord: today,
      ));
    } catch (e) {
      emit(state.copyWith(
        isHistoryLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onChangeLocationSimulationMode(
    ChangeLocationSimulationMode event,
    Emitter<AttendanceState> emit,
  ) async {
    await locationService.setSimulationMode(event.mode);
    final location = await locationService.getCurrentLocation();
    emit(state.copyWith(
      simulationMode: event.mode,
      lastLocationResult: location,
      isOutsideGeofence: !location.isWithinGeofence,
      distanceMeters: location.distanceToOfficeMeters,
      clearMessages: true,
    ));
  }

  Future<void> _onSetCustomLocationCoordinates(
    SetCustomLocationCoordinates event,
    Emitter<AttendanceState> emit,
  ) async {
    await locationService.setCustomCoordinates(event.latitude, event.longitude);
    final location = await locationService.getCurrentLocation();
    emit(state.copyWith(
      lastLocationResult: location,
      isOutsideGeofence: !location.isWithinGeofence,
      distanceMeters: location.distanceToOfficeMeters,
    ));
  }

  Future<void> _onSetOfficeCoordinates(
    SetOfficeCoordinatesEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    await locationService.setOfficeCoordinates(
      event.latitude,
      event.longitude,
      event.radiusMeters,
    );
    final location = await locationService.getCurrentLocation();
    emit(state.copyWith(
      lastLocationResult: location,
      isOutsideGeofence: !location.isWithinGeofence,
      distanceMeters: location.distanceToOfficeMeters,
    ));
  }
}
