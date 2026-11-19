import 'package:flutter/material.dart';
import 'package:rebs_hrms/core/utils/date_time_utils.dart';
import 'package:rebs_hrms/features/attendance/domain/entities/attendance_record.dart';

class RecentAttendanceList extends StatelessWidget {
  final List<AttendanceRecord> records;
  final VoidCallback onViewAll;

  const RecentAttendanceList({
    super.key,
    required this.records,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Attendance (Latest 5)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('View History ➔'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (records.isEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No attendance records found yet.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.take(5).length,
                separatorBuilder: (context, index) => const Divider(height: 16, color: Color(0xFFE2E8F0)),
                itemBuilder: (context, index) {
                  final record = records[index];
                  final inTime = record.checkInTime;
                  final outTime = record.checkOutTime;

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF475569)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.date,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'In: ${inTime != null ? DateTimeUtils.toDisplayTime(inTime) : '--'} • Out: ${outTime != null ? DateTimeUtils.toDisplayTime(outTime) : '--'}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          record.durationMinutes > 0
                              ? DateTimeUtils.formatDurationMinutes(record.durationMinutes)
                              : '0m',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
