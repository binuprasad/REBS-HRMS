import 'package:rebs_hrms/core/error/failures.dart';
import 'package:rebs_hrms/core/utils/date_time_utils.dart';
import '../entities/leave_request.dart';
import '../repositories/leave_repository.dart';

class SubmitLeaveRequestUseCase {
  final LeaveRepository repository;

  SubmitLeaveRequestUseCase(this.repository);

  Future<LeaveRequest> execute({
    required LeaveType leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cleanStart = DateTime(startDate.year, startDate.month, startDate.day);
    final cleanEnd = DateTime(endDate.year, endDate.month, endDate.day);

    // Rule: Start date cannot be before current company date
    if (cleanStart.isBefore(today)) {
      throw const ValidationFailure('Start date cannot be before the current company date.');
    }

    // Rule: End date cannot be before start date
    if (cleanEnd.isBefore(cleanStart)) {
      throw const ValidationFailure('End date cannot be before the start date.');
    }

    // Rule: Reason must contain at least 10 non-whitespace characters
    final nonWhitespaceCount = reason.replaceAll(RegExp(r'\s+'), '').length;
    if (nonWhitespaceCount < 10) {
      throw ValidationFailure(
        'Reason must contain at least 10 non-whitespace characters (currently: $nonWhitespaceCount).',
      );
    }

    // Calculate requested days
    final requestedDays = cleanEnd.difference(cleanStart).inDays + 1;

    // Rule: Requested days cannot exceed available balance
    final balance = await repository.getLeaveBalance();
    final available = leaveType == LeaveType.casual
        ? balance.casual.available
        : balance.sick.available;

    if (requestedDays > available) {
      throw ValidationFailure(
        'Requested days ($requestedDays) exceed available ${leaveType.displayName} balance ($available days).',
      );
    }

    // Rule: Dates cannot overlap an existing Pending or Approved request
    final existingRequests = await repository.getLeaveRequests();
    final startStr = DateTimeUtils.toDateString(cleanStart);
    final endStr = DateTimeUtils.toDateString(cleanEnd);

    final hasOverlap = existingRequests.any((req) {
      if (req.status != LeaveStatus.pending && req.status != LeaveStatus.approved) {
        return false;
      }
      // Overlap: start <= existing.end && end >= existing.start
      return startStr.compareTo(req.endDate) <= 0 && endStr.compareTo(req.startDate) >= 0;
    });

    if (hasOverlap) {
      throw const ValidationFailure(
        'Selected dates overlap with an existing Pending or Approved leave request.',
      );
    }

    return repository.submitLeaveRequest(
      leaveType: leaveType,
      startDate: cleanStart,
      endDate: cleanEnd,
      reason: reason.trim(),
    );
  }
}
