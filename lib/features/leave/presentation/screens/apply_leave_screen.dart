import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rebs_hrms/core/utils/date_time_utils.dart';
import 'package:rebs_hrms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:rebs_hrms/features/dashboard/presentation/bloc/dashboard_event.dart';
import '../../domain/entities/leave_request.dart';
import '../bloc/leave_bloc.dart';
import '../bloc/leave_event.dart';
import '../bloc/leave_state.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  LeaveType _selectedType = LeaveType.casual;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();
  int _nonWhitespaceCount = 0;
  String? _clientValidationError;

  @override
  void initState() {
    super.initState();
    // Default to tomorrow or today
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate;

    _reasonController.addListener(() {
      final nonWs = _reasonController.text.replaceAll(RegExp(r'\s+'), '').length;
      if (nonWs != _nonWhitespaceCount) {
        setState(() {
          _nonWhitespaceCount = nonWs;
          _clientValidationError = null; // Clear on type
        });
      }
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _calculatedDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
        _clientValidationError = null;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minEnd = _startDate ?? today;

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate != null && !_endDate!.isBefore(minEnd) ? _endDate! : minEnd,
      firstDate: minEnd,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _clientValidationError = null;
      });
    }
  }

  void _submitForm(LeaveState state) {
    setState(() => _clientValidationError = null);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Rule 1: Offline check
    if (state.isOffline) {
      setState(() {
        _clientValidationError =
            'Leave submission requires an active network connection. You are currently offline.';
      });
      return;
    }

    if (_startDate == null || _endDate == null) {
      setState(() => _clientValidationError = 'Please select valid start and end dates.');
      return;
    }

    // Rule 2: Start date cannot be before current company date
    if (_startDate!.isBefore(today)) {
      setState(() {
        _clientValidationError = 'Start date cannot be before the current company date.';
      });
      return;
    }

    // Rule 3: End date cannot be before start date
    if (_endDate!.isBefore(_startDate!)) {
      setState(() {
        _clientValidationError = 'End date cannot be before the start date.';
      });
      return;
    }

    // Rule 4: Reason must contain at least 10 non-whitespace characters
    if (_nonWhitespaceCount < 10) {
      setState(() {
        _clientValidationError =
            'Reason must contain at least 10 non-whitespace characters (currently: $_nonWhitespaceCount).';
      });
      return;
    }

    // Rule 5: Requested days cannot exceed available balance
    final balance = state.balance;
    if (balance != null) {
      final available = _selectedType == LeaveType.casual
          ? balance.casual.available
          : balance.sick.available;

      if (_calculatedDays > available) {
        setState(() {
          _clientValidationError =
              'Requested $_calculatedDays days exceed your available ${_selectedType.displayName} balance ($available days).';
        });
        return;
      }
    }

    // Rule 6: Dates cannot overlap an existing Pending or Approved request
    final startStr = DateTimeUtils.toDateString(_startDate!);
    final endStr = DateTimeUtils.toDateString(_endDate!);

    final hasOverlap = state.requests.any((req) {
      if (req.status != LeaveStatus.pending && req.status != LeaveStatus.approved) {
        return false;
      }
      return startStr.compareTo(req.endDate) <= 0 && endStr.compareTo(req.startDate) >= 0;
    });

    if (hasOverlap) {
      setState(() {
        _clientValidationError =
            'Selected dates overlap with an existing Pending or Approved leave request in your records.';
      });
      return;
    }

    // Submit event to BLoC
    context.read<LeaveBloc>().add(
          SubmitLeaveApplication(
            leaveType: _selectedType,
            startDate: _startDate!,
            endDate: _endDate!,
            reason: _reasonController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Leave'),
      ),
      body: BlocConsumer<LeaveBloc, LeaveState>(
        listener: (context, state) {
          if (state.submissionSuccess != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✓ Leave application ${state.submissionSuccess!.id} submitted successfully!',
                ),
                backgroundColor: const Color(0xFF059669),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<LeaveBloc>().add(const ResetLeaveSubmissionState());
            // Refresh dashboard so updated leave balance reflects immediately
            context.read<DashboardBloc>().add(const RefreshDashboardSilently());
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          final isSubmitting = state.isSubmitting;
          final balance = state.balance;
          final availableCasual = balance?.casual.available ?? 0;
          final availableSick = balance?.sick.available ?? 0;
          final activeAvailable =
              _selectedType == LeaveType.casual ? availableCasual : availableSick;

          // Error to display (either client validation or server rejection)
          final displayError = _clientValidationError ?? state.errorMessage;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offline warning banner
                  if (state.isOffline) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off_rounded, color: Color(0xFFD97706), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Device is offline. Leave submission requires active internet connectivity.',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Server or Client Error Banner
                  if (displayError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_rounded, color: Color(0xFFB91C1C), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Validation / Submission Error',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB91C1C),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayError,
                                  style: const TextStyle(
                                    color: Color(0xFF7F1D1D),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Leave Type Selector
                  const Text(
                    'Leave Type',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<LeaveType>(
                    segments: [
                      ButtonSegment(
                        value: LeaveType.casual,
                        label: Text('Casual ($availableCasual left)'),
                        icon: const Icon(Icons.beach_access_rounded),
                      ),
                      ButtonSegment(
                        value: LeaveType.sick,
                        label: Text('Sick ($availableSick left)'),
                        icon: const Icon(Icons.medical_services_rounded),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedType = newSelection.first;
                        _clientValidationError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Dates Selection Row
                  const Text(
                    'Leave Duration (Calendar Days)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickStartDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'START DATE',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month, size: 16, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 6),
                                    Text(
                                      _startDate != null
                                          ? DateTimeUtils.toDateString(_startDate!)
                                          : 'Select',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickEndDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'END DATE',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month, size: 16, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 6),
                                    Text(
                                      _endDate != null
                                          ? DateTimeUtils.toDateString(_endDate!)
                                          : 'Select',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Calculated Duration Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _calculatedDays > activeAvailable
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Days: $_calculatedDays calendar days',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _calculatedDays > activeAvailable
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF334155),
                          ),
                        ),
                        Text(
                          'Available: $activeAvailable days',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _calculatedDays > activeAvailable
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reason Field with Character Count (>= 10 non-whitespace rule)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reason for Leave',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$_nonWhitespaceCount / 10 non-space chars',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _nonWhitespaceCount >= 10
                              ? const Color(0xFF15803D)
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter reason for leave (minimum 10 non-whitespace characters)...',
                      helperText: 'e.g. Attending family function, medical appointment',
                      helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting ? null : () => _submitForm(state),
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        isSubmitting ? 'Validating & Submitting...' : 'Submit Application',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
