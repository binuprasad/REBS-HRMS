import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rebs_hrms/core/di/service_locator.dart';
import 'package:rebs_hrms/core/location/location_service.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:rebs_hrms/features/attendance/presentation/bloc/attendance_state.dart';

class LocationSimulatorDialog extends StatefulWidget {
  const LocationSimulatorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<AttendanceBloc>(),
        child: const LocationSimulatorDialog(),
      ),
    );
  }

  @override
  State<LocationSimulatorDialog> createState() => _LocationSimulatorDialogState();
}

class _LocationSimulatorDialogState extends State<LocationSimulatorDialog> {
  late LocationService _locationService;
  late LocationSimulationMode _selectedMode;
  late TextEditingController _customLatController;
  late TextEditingController _customLngController;
  late TextEditingController _officeLatController;
  late TextEditingController _officeLngController;
  late TextEditingController _radiusController;
  bool _showOfficeConfig = false;

  @override
  void initState() {
    super.initState();
    _locationService = sl<LocationService>();
    _selectedMode = _locationService.simulationMode;
    _customLatController = TextEditingController(text: '12.971598');
    _customLngController = TextEditingController(text: '77.594566');
    _officeLatController = TextEditingController(text: _locationService.officeLatitude.toString());
    _officeLngController = TextEditingController(text: _locationService.officeLongitude.toString());
    _radiusController = TextEditingController(text: _locationService.geofenceRadiusMeters.toInt().toString());
  }

  @override
  void dispose() {
    _customLatController.dispose();
    _customLngController.dispose();
    _officeLatController.dispose();
    _officeLngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AttendanceBloc, AttendanceState>(
      builder: (context, state) {
        final lastResult = state.lastLocationResult;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.location_on, color: Colors.blue.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'GPS Simulator',
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
                  'Simulate employee location for geofence verification (200m rule):',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 14),

                // Options
                _buildModeTile(
                  mode: LocationSimulationMode.atOffice,
                  title: '🏢 At Office (Within 200m)',
                  subtitle: 'Simulates exact office coordinates (0m away)',
                  color: Colors.green,
                ),
                const SizedBox(height: 8),

                _buildModeTile(
                  mode: LocationSimulationMode.outsideOffice,
                  title: '🚗 Remote / Outside (1.5 km)',
                  subtitle: 'Simulates location ~1500m outside geofence',
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),

                _buildModeTile(
                  mode: LocationSimulationMode.device,
                  title: '📱 Real Device GPS',
                  subtitle: 'Reads hardware GPS coordinates via geolocator',
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),

                _buildModeTile(
                  mode: LocationSimulationMode.custom,
                  title: '🎯 Custom Coordinates',
                  subtitle: 'Enter specific latitude and longitude',
                  color: Colors.purple,
                ),

                if (_selectedMode == LocationSimulationMode.custom) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customLatController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _customLngController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Live Geofence Status
                if (lastResult != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lastResult.isWithinGeofence
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: lastResult.isWithinGeofence
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          lastResult.isWithinGeofence
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: lastResult.isWithinGeofence
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB91C1C),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lastResult.isWithinGeofence
                                    ? 'Within Office Geofence'
                                    : 'Outside Geofence Perimeter',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: lastResult.isWithinGeofence
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                              Text(
                                'Distance: ${lastResult.distanceToOfficeMeters.round()}m (Limit: ${_locationService.geofenceRadiusMeters.round()}m)',
                                style: const TextStyle(fontSize: 11, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Location Permission Helpers
                if (state.isLocationPermissionPermanentlyDenied) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Geolocator.openAppSettings(),
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Open App Settings (Permission Denied)'),
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(),

                // Configurable Office Coordinates Expandable
                InkWell(
                  onTap: () => setState(() => _showOfficeConfig = !_showOfficeConfig),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🏢 Office Coordinates & Radius',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Icon(
                          _showOfficeConfig
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showOfficeConfig) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _officeLatController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Office Lat', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _officeLngController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Office Lng', isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _radiusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Radius (Meters)', isDense: true),
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
              onPressed: () {
                final bloc = context.read<AttendanceBloc>();

                // Save custom coordinates if custom mode selected
                if (_selectedMode == LocationSimulationMode.custom) {
                  final lat = double.tryParse(_customLatController.text) ?? 12.971598;
                  final lng = double.tryParse(_customLngController.text) ?? 77.594566;
                  bloc.add(SetCustomLocationCoordinates(lat, lng));
                }

                // Save office configuration if modified
                if (_showOfficeConfig) {
                  final oLat = double.tryParse(_officeLatController.text) ?? 12.971598;
                  final oLng = double.tryParse(_officeLngController.text) ?? 77.594566;
                  final rad = double.tryParse(_radiusController.text) ?? 200.0;
                  bloc.add(SetOfficeCoordinatesEvent(
                    latitude: oLat,
                    longitude: oLng,
                    radiusMeters: rad,
                  ));
                }

                bloc.add(ChangeLocationSimulationMode(_selectedMode));
                Navigator.pop(context);
              },
              child: const Text('Apply Mode'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModeTile({
    required LocationSimulationMode mode,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedMode == mode;
    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? color : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
