import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/sync/sync_bloc.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/sync/sync_event.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/sync/sync_state.dart';
import 'package:rebs_hrms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:rebs_hrms/features/dashboard/presentation/bloc/dashboard_event.dart';

class SyncIndicatorButton extends StatelessWidget {
  const SyncIndicatorButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyncBloc, SyncState>(
      listener: (context, state) {
        if (state is SyncSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sync completed: ${state.result.syncedCount} synced, ${state.result.rejectedCount} rejected.',
              ),
              backgroundColor: state.result.hasFailures
                  ? Colors.orange.shade800
                  : Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          // Refresh dashboard snapshot silently
          context.read<DashboardBloc>().add(const RefreshDashboardSilently());
        } else if (state is SyncFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSyncing = state is SyncInProgress;
        final isConnected = state.isConnected;
        final pendingCount = state.pendingCount;

        Color bgColor;
        Color fgColor;
        Widget iconWidget;
        String label;

        if (isSyncing) {
          bgColor = const Color(0xFFDBEAFE);
          fgColor = const Color(0xFF1D4ED8);
          iconWidget = SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          );
          label = 'Syncing...';
        } else if (!isConnected) {
          bgColor = const Color(0xFFFEF3C7);
          fgColor = const Color(0xFFB45309);
          iconWidget = Icon(Icons.cloud_off_rounded, size: 16, color: fgColor);
          label = pendingCount > 0 ? '$pendingCount offline' : 'Offline';
        } else if (pendingCount > 0) {
          bgColor = const Color(0xFFFFEDD5);
          fgColor = const Color(0xFFC2410C);
          iconWidget = Icon(Icons.sync_rounded, size: 16, color: fgColor);
          label = '$pendingCount to sync';
        } else {
          bgColor = const Color(0xFFDCFCE7);
          fgColor = const Color(0xFF15803D);
          iconWidget = Icon(Icons.cloud_done_rounded, size: 16, color: fgColor);
          label = 'Synced';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: InkWell(
            onTap: () {
              if (pendingCount > 0 && isConnected && !isSyncing) {
                context.read<SyncBloc>().add(const SyncNowRequested());
              } else {
                _showSyncStatusSheet(context, state);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: fgColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconWidget,
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: fgColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSyncStatusSheet(BuildContext context, SyncState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🔄 Offline Sync Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    state.isConnected ? Icons.wifi : Icons.wifi_off,
                    color: state.isConnected ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    state.isConnected ? 'Internet Connected' : 'Device is Offline',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    state.isConnected
                        ? 'Auto-sync active when new attendance events are recorded.'
                        : 'Events are saved locally in Hive and queued for auto-sync.',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.pending_actions_rounded, color: Colors.orange),
                  title: Text(
                    '${state.pendingCount} Pending Attendance Event(s)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Stored with unique clientEventId (UUID) in strict FIFO order.',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.isConnected && state.pendingCount > 0
                        ? () {
                            Navigator.pop(bottomSheetContext);
                            context.read<SyncBloc>().add(const SyncNowRequested());
                          }
                        : null,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Now'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
