import 'package:flutter/material.dart';
import 'package:rebs_hrms/core/widgets/location_simulator_dialog.dart';
import 'package:rebs_hrms/core/widgets/settings_debug_modal.dart';
import 'package:rebs_hrms/core/widgets/sync_indicator_button.dart';
import 'package:rebs_hrms/features/attendance/presentation/screens/attendance_history_screen.dart';
import 'package:rebs_hrms/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:rebs_hrms/features/leave/presentation/screens/leave_history_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigateToAttendance: () => setState(() => _currentIndex = 1),
        onNavigateToLeave: () => setState(() => _currentIndex = 2),
      ),
      const AttendanceHistoryScreen(),
      const LeaveHistoryScreen(),
    ];

    final titles = [
      'Employee Workspace',
      'Attendance Records',
      'Leave Management',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.business_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'REBS HRMS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  titles[_currentIndex],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Live Sync & Offline Indicator
          const SyncIndicatorButton(),

          // GPS Location Simulator Trigger
          IconButton(
            icon: const Icon(Icons.location_searching_rounded),
            tooltip: 'GPS Location Simulator',
            onPressed: () => LocationSimulatorDialog.show(context),
          ),

          // Server / ngrok Settings Modal Trigger
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Server & ngrok Settings',
            onPressed: () => SettingsDebugModal.show(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_filled_rounded),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.beach_access_outlined),
            selectedIcon: Icon(Icons.beach_access_rounded),
            label: 'Leaves',
          ),
        ],
      ),
    );
  }
}
