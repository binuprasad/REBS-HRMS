import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/get_leave_balance_usecase.dart';
import '../../domain/usecases/get_leave_requests_usecase.dart';
import '../../domain/usecases/submit_leave_request_usecase.dart';
import 'leave_event.dart';
import 'leave_state.dart';

class LeaveBloc extends Bloc<LeaveEvent, LeaveState> {
  final GetLeaveBalanceUseCase getLeaveBalanceUseCase;
  final GetLeaveRequestsUseCase getLeaveRequestsUseCase;
  final SubmitLeaveRequestUseCase submitLeaveRequestUseCase;

  LeaveBloc({
    required this.getLeaveBalanceUseCase,
    required this.getLeaveRequestsUseCase,
    required this.submitLeaveRequestUseCase,
  }) : super(const LeaveState()) {
    on<LoadLeaveData>(_onLoadLeaveData);
    on<SubmitLeaveApplication>(_onSubmitLeaveApplication);
    on<ResetLeaveSubmissionState>(_onResetLeaveSubmissionState);
  }

  Future<void> _onLoadLeaveData(
    LoadLeaveData event,
    Emitter<LeaveState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));
    try {
      final balance = await getLeaveBalanceUseCase.execute(forceRefresh: event.forceRefresh);
      final requests = await getLeaveRequestsUseCase.execute(forceRefresh: event.forceRefresh);

      emit(state.copyWith(
        isLoading: false,
        balance: balance,
        requests: requests,
        isOffline: false,
      ));
    } on NetworkFailure catch (e) {
      // In offline mode, get whatever is cached
      try {
        final requests = await getLeaveRequestsUseCase.execute();
        final balance = await getLeaveBalanceUseCase.execute();
        emit(state.copyWith(
          isLoading: false,
          balance: balance,
          requests: requests,
          isOffline: true,
        ));
      } catch (_) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: e.message,
          isOffline: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onSubmitLeaveApplication(
    SubmitLeaveApplication event,
    Emitter<LeaveState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      final created = await submitLeaveRequestUseCase.execute(
        leaveType: event.leaveType,
        startDate: event.startDate,
        endDate: event.endDate,
        reason: event.reason,
      );

      // Refresh requests and balance
      final updatedRequests = await getLeaveRequestsUseCase.execute(forceRefresh: true);
      final updatedBalance = await getLeaveBalanceUseCase.execute(forceRefresh: true);

      emit(state.copyWith(
        isSubmitting: false,
        requests: updatedRequests,
        balance: updatedBalance,
        submissionSuccess: created,
      ));
    } on Failure catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  void _onResetLeaveSubmissionState(
    ResetLeaveSubmissionState event,
    Emitter<LeaveState> emit,
  ) {
    emit(state.copyWith(clearMessages: true));
  }
}
