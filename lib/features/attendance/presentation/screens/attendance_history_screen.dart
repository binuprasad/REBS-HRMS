import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rebs_hrms/core/utils/date_time_utils.dart';
import 'package:rebs_hrms/core/widgets/location_simulator_dialog.dart';
import 'package:rebs_hrms/features/attendance/domain/entities/attendance_record.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/attendance_state.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        final records = state.history;
        final isBusy = state.isActionInProgress;
        final todayRecord = state.todayRecord;
        final todayStatus = todayRecord?.sessionStatus ?? TodayAttendanceStatus.notCheckedIn;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<AttendanceBloc>().add(const LoadAttendanceHistory(forceRefresh: true));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Attendance Action Banner
                _buildActionBanner(context, todayStatus, isBusy),
                const SizedBox(height: 16),

                // History Header & Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attendance History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Showing ${records.length} records',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    IconButton.outlined(
                      onPressed: () => LocationSimulatorDialog.show(context),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      tooltip: 'GPS Simulation Config',
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (state.isHistoryLoading && records.isEmpty) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else if (records.isEmpty) ...[
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
                        Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFF94A3B8)),
                        SizedBox(height: 12),
                        Text(
                          'No attendance records found',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Recorded sessions will appear here.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildAttendanceCard(records[index]);
                    },
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionBanner(
    BuildContext context,
    TodayAttendanceStatus todayStatus,
    bool isBusy,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today Session Action',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: todayStatus == TodayAttendanceStatus.checkedIn
                      ? const Color(0xFFDBEAFE)
                      : todayStatus == TodayAttendanceStatus.checkedOut
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  todayStatus.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: todayStatus == TodayAttendanceStatus.checkedIn
                        ? const Color(0xFF1D4ED8)
                        : todayStatus == TodayAttendanceStatus.checkedOut
                            ? const Color(0xFF15803D)
                            : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (todayStatus == TodayAttendanceStatus.notCheckedIn) ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: isBusy
                    ? null
                    : () => context.read<AttendanceBloc>().add(const CheckInRequested()),
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(isBusy ? 'Checking In...' : 'Check In'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
              ),
            ),
          ] else if (todayStatus == TodayAttendanceStatus.checkedIn) ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: isBusy
                    ? null
                    : () => context.read<AttendanceBloc>().add(const CheckOutRequested()),
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
                label: Text(isBusy ? 'Checking Out...' : 'Check Out'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  '✓ Checked in & checked out for today',
                  style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    final inTime = record.checkInTime;
    final outTime = record.checkOutTime;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    record.date,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              // Synced Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF15803D)),
                    SizedBox(width: 4),
                    Text(
                      'Synced',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Check-In', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      inTime != null ? DateTimeUtils.toDisplayTime(inTime) : '--:--',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Check-Out', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      outTime != null ? DateTimeUtils.toDisplayTime(outTime) : '--:--',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Duration', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      record.durationMinutes > 0
                          ? DateTimeUtils.formatDurationMinutes(record.durationMinutes)
                          : '--',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
