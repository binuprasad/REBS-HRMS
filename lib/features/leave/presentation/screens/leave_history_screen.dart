import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rebs_hrms/core/widgets/offline_banner.dart';
import '../../domain/entities/leave_request.dart';
import '../bloc/leave_bloc.dart';
import '../bloc/leave_event.dart';
import '../bloc/leave_state.dart';
import 'apply_leave_screen.dart';

class LeaveHistoryScreen extends StatelessWidget {
  const LeaveHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Apply Leave'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<LeaveBloc, LeaveState>(
        builder: (context, state) {
          final balance = state.balance;
          final requests = state.requests;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<LeaveBloc>().add(const LoadLeaveData(forceRefresh: true));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offline banner
                  if (state.isOffline)
                    OfflineBanner(
                      message: 'Viewing cached leave history while offline.',
                      onRetry: () => context.read<LeaveBloc>().add(const LoadLeaveData(forceRefresh: true)),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Balances Header Card
                        _buildBalanceSummary(balance),
                        const SizedBox(height: 20),

                        // Section Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'My Leave Applications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${requests.length} requests',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (state.isLoading && requests.isEmpty) ...[
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ] else if (requests.isEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.beach_access_rounded, size: 48, color: Color(0xFF94A3B8)),
                                SizedBox(height: 12),
                                Text(
                                  'No leave applications found',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tap "Apply Leave" below to submit an application.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: requests.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildRequestCard(requests[index]);
                            },
                          ),
                        ],
                        const SizedBox(height: 80), // Room for FAB
                      ],
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

  Widget _buildBalanceSummary(dynamic balance) {
    final casual = balance?.casual;
    final sick = balance?.sick;
    final totalAvailable = balance?.totalAvailable ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Leave Quota',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuotaPill(
                  label: 'Casual Leave',
                  available: casual?.available ?? 0,
                  total: casual?.total ?? 0,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuotaPill(
                  label: 'Sick Leave',
                  available: sick?.available ?? 0,
                  total: sick?.total ?? 0,
                  color: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuotaPill(
                  label: 'Total Available',
                  available: totalAvailable,
                  total: (casual?.total ?? 0) + (sick?.total ?? 0),
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaPill({
    required String label,
    required int available,
    required int total,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(LeaveRequest req) {
    Color statusBg;
    Color statusFg;
    IconData statusIcon;

    switch (req.status) {
      case LeaveStatus.approved:
        statusBg = const Color(0xFFDCFCE7);
        statusFg = const Color(0xFF15803D);
        statusIcon = Icons.check_circle_rounded;
        break;
      case LeaveStatus.rejected:
        statusBg = const Color(0xFFFEE2E2);
        statusFg = const Color(0xFFB91C1C);
        statusIcon = Icons.cancel_rounded;
        break;
      case LeaveStatus.pending:
        statusBg = const Color(0xFFFEF3C7);
        statusFg = const Color(0xFFB45309);
        statusIcon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Leave Type, Days, Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: req.leaveType == LeaveType.casual
                          ? const Color(0xFFDBEAFE)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      req.leaveType == LeaveType.casual
                          ? Icons.beach_access_rounded
                          : Icons.medical_services_rounded,
                      size: 16,
                      color: req.leaveType == LeaveType.casual
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    req.leaveType.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${req.days} ${req.days == 1 ? "day" : "days"})',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusFg),
                    const SizedBox(width: 4),
                    Text(
                      req.status.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Date Range
          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                '${req.startDate}  ➔  ${req.endDate}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Reason
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              req.reason,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}
