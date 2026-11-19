import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rebs_hrms/core/constants/api_endpoints.dart';
import 'package:rebs_hrms/core/di/service_locator.dart';
import 'package:rebs_hrms/core/network/dio_client.dart';
import 'package:rebs_hrms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:rebs_hrms/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:rebs_hrms/features/leave/presentation/bloc/leave_bloc.dart';
import 'package:rebs_hrms/features/leave/presentation/bloc/leave_event.dart';

class SettingsDebugModal extends StatefulWidget {
  const SettingsDebugModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const SettingsDebugModal(),
    );
  }

  @override
  State<SettingsDebugModal> createState() => _SettingsDebugModalState();
}

class _SettingsDebugModalState extends State<SettingsDebugModal> {
  late final DioClient _dioClient;
  late final TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool? _isTestSuccess;

  @override
  void initState() {
    super.initState();
    _dioClient = sl<DioClient>();
    _urlController = TextEditingController(text: _dioClient.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
      _isTestSuccess = null;
    });

    final testUrl = _urlController.text.trim();
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dioClient.dio.get('$testUrl${ApiEndpoints.employeeMe}');
      stopwatch.stop();
      if (response.statusCode == 200) {
        setState(() {
          _isTesting = false;
          _isTestSuccess = true;
          _testResult = '✓ Connected successfully in ${stopwatch.elapsedMilliseconds}ms!';
        });
      } else {
        setState(() {
          _isTesting = false;
          _isTestSuccess = false;
          _testResult = 'Server returned HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _isTesting = false;
        _isTestSuccess = false;
        _testResult = 'Connection failed: ${e.toString().split('\n').first}';
      });
    }
  }

  Future<void> _saveAndApply() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) return;

    await _dioClient.updateBaseUrl(newUrl);

    if (mounted) {
      // Refresh app data with new endpoint
      context.read<DashboardBloc>().add(const LoadDashboard(forceRefresh: true));
      context.read<LeaveBloc>().add(const LoadLeaveData(forceRefresh: true));

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API Base URL updated to: $newUrl'),
          backgroundColor: Colors.indigo,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.settings_ethernet_rounded, color: Colors.indigo.shade700, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Server / ngrok Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure the Mock API Server URL (e.g. for ngrok or physical devices):',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'https://xxxx.ngrok-free.app or http://10.0.2.2:8080',
                prefixIcon: Icon(Icons.link_rounded),
                isDense: true,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 10),

            // Quick Presets
            const Text(
              'Quick Presets:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('localhost:8080 (ADB Reverse)', style: TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _urlController.text = 'http://localhost:8080'),
                ),
                ActionChip(
                  label: const Text('192.168.43.180:8080 (LAN)', style: TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _urlController.text = 'http://192.168.43.180:8080'),
                ),
                ActionChip(
                  label: const Text('10.0.2.2:8080 (Emulator)', style: TextStyle(fontSize: 11)),
                  onPressed: () => setState(() => _urlController.text = 'http://10.0.2.2:8080'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Test Connection Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.network_check_rounded, size: 16),
                label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
              ),
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isTestSuccess == true
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isTestSuccess == true
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Text(
                  _testResult!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isTestSuccess == true
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAndApply,
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}
