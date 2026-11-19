import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rebs_hrms/core/widgets/offline_banner.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/leave_balance_preview_card.dart';
import '../widgets/recent_attendance_list.dart';
import '../widgets/today_attendance_card.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToAttendance;
  final VoidCallback onNavigateToLeave;

  const DashboardScreen({
    super.key,
    required this.onNavigateToAttendance,
    required this.onNavigateToLeave,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading workspace...',
                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        if (state is DashboardError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade600),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to Load Dashboard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<DashboardBloc>().add(const LoadDashboard(forceRefresh: true));
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is DashboardEmpty) {
          return Center(
            child: Text(state.message, style: const TextStyle(color: Color(0xFF64748B))),
          );
        }

        if (state is DashboardLoaded) {
          final data = state.data;
          final employee = data.employee;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DashboardBloc>().add(const LoadDashboard(forceRefresh: true));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offline Banner
                  if (data.isOffline)
                    OfflineBanner(
                      message: 'Viewing cached dashboard data while offline.',
                      onRetry: () => context.read<DashboardBloc>().add(const LoadDashboard(forceRefresh: true)),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Employee Profile Summary Header
                        _buildEmployeeHeader(employee),
                        const SizedBox(height: 16),

                        // Today's Attendance Card with live ticker & action buttons
                        TodayAttendanceCard(loadedState: state),
                        const SizedBox(height: 16),

                        // Leave Balance Preview
                        LeaveBalancePreviewCard(
                          balance: data.leaveBalance,
                          onApplyLeave: onNavigateToLeave,
                        ),
                        const SizedBox(height: 16),

                        // Recent Attendance History (Latest 5)
                        RecentAttendanceList(
                          records: data.recentAttendanceRecords,
                          onViewAll: onNavigateToAttendance,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmployeeHeader(dynamic employee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF1E3A8A),
            child: Text(
              (employee.name as String).substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        employee.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        employee.id,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${employee.department} • ${employee.role}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
