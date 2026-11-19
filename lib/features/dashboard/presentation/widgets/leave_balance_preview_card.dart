import 'package:flutter/material.dart';
import 'package:rebs_hrms/features/leave/domain/entities/leave_balance.dart';

class LeaveBalancePreviewCard extends StatelessWidget {
  final LeaveBalance? balance;
  final VoidCallback onApplyLeave;

  const LeaveBalancePreviewCard({
    super.key,
    required this.balance,
    required this.onApplyLeave,
  });

  @override
  Widget build(BuildContext context) {
    final casual = balance?.casual;
    final sick = balance?.sick;
    final total = balance?.totalAvailable ?? 0;

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
                  'Leave Balance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton.icon(
                  onPressed: onApplyLeave,
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Apply'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceItem(
                    title: 'Casual Leave',
                    available: casual?.available ?? 0,
                    total: casual?.total ?? 0,
                    color: const Color(0xFF2563EB),
                    icon: Icons.beach_access_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBalanceItem(
                    title: 'Sick Leave',
                    available: sick?.available ?? 0,
                    total: sick?.total ?? 0,
                    color: const Color(0xFFD97706),
                    icon: Icons.medical_services_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Available Quota',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  Text(
                    '$total Days',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem({
    required String title,
    required int available,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$available',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                ' / $total days',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
