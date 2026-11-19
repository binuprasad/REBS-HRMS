import 'package:equatable/equatable.dart';
import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_request.dart';

class LeaveState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final LeaveBalance? balance;
  final List<LeaveRequest> requests;
  final LeaveRequest? submissionSuccess;
  final String? errorMessage;
  final bool isOffline;

  const LeaveState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.balance,
    this.requests = const [],
    this.submissionSuccess,
    this.errorMessage,
    this.isOffline = false,
  });

  LeaveState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    LeaveBalance? balance,
    List<LeaveRequest>? requests,
    LeaveRequest? submissionSuccess,
    String? errorMessage,
    bool? isOffline,
    bool clearMessages = false,
  }) {
    return LeaveState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      balance: balance ?? this.balance,
      requests: requests ?? this.requests,
      submissionSuccess: clearMessages ? null : (submissionSuccess ?? this.submissionSuccess),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSubmitting,
        balance,
        requests,
        submissionSuccess,
        errorMessage,
        isOffline,
      ];
}
