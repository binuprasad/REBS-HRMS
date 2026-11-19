import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rebs_hrms/core/utils/date_time_utils.dart';
import 'package:rebs_hrms/core/widgets/location_simulator_dialog.dart';
import 'package:rebs_hrms/features/attendance/domain/entities/attendance_record.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:rebs_hrms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:rebs_hrms/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:rebs_hrms/features/dashboard/presentation/bloc/dashboard_state.dart';

class TodayAttendanceCard extends StatelessWidget {
  final DashboardLoaded loadedState;

  const TodayAttendanceCard({super.key, required this.loadedState});

  @override
  Widget build(BuildContext context) {
    final data = loadedState.data;
    final status = data.todayStatus;
    final checkInTime = data.checkInTime;
    final checkOutTime = data.checkOutTime;
    final formattedDuration = loadedState.formattedLiveDuration;

    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, attendanceState) {
        if (attendanceState.actionSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(attendanceState.actionSuccessMessage!),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Refresh dashboard snapshot silently
          context.read<DashboardBloc>().add(const RefreshDashboardSilently());
        } else if (attendanceState.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(attendanceState.errorMessage!),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              action: attendanceState.isOutsideGeofence
                  ? SnackBarAction(
                      label: 'GPS Config',
                      textColor: Colors.white,
                      onPressed: () => LocationSimulatorDialog.show(context),
                    )
                  : null,
            ),
          );
        }
      },
      builder: (context, attendanceState) {
        final isBusy = attendanceState.isActionInProgress;

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Date & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateTimeUtils.toDisplayDate(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Today's Attendance",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 18),

                // Live Elapsed Working Duration Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: status == TodayAttendanceStatus.checkedIn
                          ? [const Color(0xFF1E3A8A), const Color(0xFF2563EB)]
                          : status == TodayAttendanceStatus.checkedOut
                              ? [const Color(0xFF065F46), const Color(0xFF059669)]
                              : [const Color(0xFF334155), const Color(0xFF475569)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          status == TodayAttendanceStatus.checkedIn
                              ? Icons.timer_rounded
                              : Icons.access_time_filled_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status == TodayAttendanceStatus.checkedIn
                                  ? 'ELAPSED WORKING DURATION'
                                  : status == TodayAttendanceStatus.checkedOut
                                      ? 'TOTAL SESSION COMPLETED'
                                      : 'NOT STARTED',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              status == TodayAttendanceStatus.checkedIn
                                  ? formattedDuration
                                  : status == TodayAttendanceStatus.checkedOut
                                      ? DateTimeUtils.formatDurationMinutes(data.elapsedWorkingMinutes)
                                      : '--:--:--',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Check In / Check Out Details Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeMetric(
                        label: 'Check-In',
                        time: checkInTime != null ? DateTimeUtils.toDisplayTime(checkInTime) : '--:--',
                        icon: Icons.login_rounded,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeMetric(
                        label: 'Check-Out',
                        time: checkOutTime != null ? DateTimeUtils.toDisplayTime(checkOutTime) : '--:--',
                        icon: Icons.logout_rounded,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location info pill with simulator trigger
                InkWell(
                  onTap: () => LocationSimulatorDialog.show(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            attendanceState.simulationMode.displayName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text(
                          'Configure ➔',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons with Double-Tap Protection
                if (status == TodayAttendanceStatus.notCheckedIn) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => context.read<AttendanceBloc>().add(const CheckInRequested()),
                      icon: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.touch_app_rounded),
                      label: Text(isBusy ? 'Recording Check-In...' : 'CHECK IN NOW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ] else if (status == TodayAttendanceStatus.checkedIn) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => context.read<AttendanceBloc>().add(const CheckOutRequested()),
                      icon: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.logout_rounded),
                      label: Text(isBusy ? 'Recording Check-Out...' : 'CHECK OUT NOW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Attendance Complete for Today',
                          style: TextStyle(
                            color: Color(0xFF15803D),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(TodayAttendanceStatus status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case TodayAttendanceStatus.checkedIn:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        text = 'Checked In';
        break;
      case TodayAttendanceStatus.checkedOut:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        text = 'Checked Out';
        break;
      case TodayAttendanceStatus.notCheckedIn:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        text = 'Not Checked In';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTimeMetric({
    required String label,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
