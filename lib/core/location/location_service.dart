import '../constants/app_constants.dart';
import '../storage/hive_service.dart';
import '../utils/geo_utils.dart';

enum LocationSimulationMode {
  device,
  atOffice,
  outsideOffice,
  custom;

  String get displayName {
    switch (this) {
      case LocationSimulationMode.device:
        return 'Real Device GPS';
      case LocationSimulationMode.atOffice:
        return 'Simulated: At Office (Within 200m)';
      case LocationSimulationMode.outsideOffice:
        return 'Simulated: Remote (Outside 200m)';
      case LocationSimulationMode.custom:
        return 'Simulated: Custom Coordinates';
    }
  }

  static LocationSimulationMode fromString(String? val) {
    switch (val) {
      case 'atOffice':
        return LocationSimulationMode.atOffice;
      case 'outsideOffice':
        return LocationSimulationMode.outsideOffice;
      case 'custom':
        return LocationSimulationMode.custom;
      case 'device':
      default:
        return LocationSimulationMode.device;
    }
  }
}

class LocationResult {
  final double latitude;
  final double longitude;
  final double distanceToOfficeMeters;
  final bool isWithinGeofence;
  final LocationSimulationMode mode;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.distanceToOfficeMeters,
    required this.isWithinGeofence,
    required this.mode,
  });
}

abstract class LocationService {
  Future<LocationResult> getCurrentLocation();
  LocationSimulationMode get simulationMode;
  Future<void> setSimulationMode(LocationSimulationMode mode);
  Future<void> setCustomCoordinates(double lat, double lng);
  Future<void> setOfficeCoordinates(double lat, double lng, double radiusMeters);
  double get officeLatitude;
  double get officeLongitude;
  double get geofenceRadiusMeters;
}

class LocationServiceImpl implements LocationService {
  final HiveService hiveService;

  LocationSimulationMode _mode = LocationSimulationMode.atOffice; // Default to atOffice so tests & reviews work immediately
  double _customLat = 12.971598;
  double _customLng = 77.594566;
  
  double _officeLat = AppConstants.defaultOfficeLatitude;
  double _officeLng = AppConstants.defaultOfficeLongitude;
  double _geofenceRadius = AppConstants.permittedGeofenceRadiusMeters;

  LocationServiceImpl({required this.hiveService}) {
    _loadSettings();
  }

  void _loadSettings() {
    try {
      final box = hiveService.settingsBox;
      final savedMode = box.get('simulation_mode') as String?;
      if (savedMode != null) {
        _mode = LocationSimulationMode.fromString(savedMode);
      }
      _customLat = (box.get('custom_lat') as num?)?.toDouble() ?? _customLat;
      _customLng = (box.get('custom_lng') as num?)?.toDouble() ?? _customLng;
      _officeLat = (box.get('office_lat') as num?)?.toDouble() ?? _officeLat;
      _officeLng = (box.get('office_lng') as num?)?.toDouble() ?? _officeLng;
      _geofenceRadius = (box.get('office_radius') as num?)?.toDouble() ?? _geofenceRadius;
    } catch (_) {
      // Fallback to defaults
    }
  }

  @override
  LocationSimulationMode get simulationMode => _mode;

  @override
  double get officeLatitude => _officeLat;

  @override
  double get officeLongitude => _officeLng;

  @override
  double get geofenceRadiusMeters => _geofenceRadius;

  @override
  Future<void> setSimulationMode(LocationSimulationMode mode) async {
    _mode = mode;
    await hiveService.settingsBox.put('simulation_mode', mode.name);
  }

  @override
  Future<void> setCustomCoordinates(double lat, double lng) async {
    _customLat = lat;
    _customLng = lng;
    await hiveService.settingsBox.put('custom_lat', lat);
    await hiveService.settingsBox.put('custom_lng', lng);
  }

  @override
  Future<void> setOfficeCoordinates(double lat, double lng, double radiusMeters) async {
    _officeLat = lat;
    _officeLng = lng;
    _geofenceRadius = radiusMeters;
    await hiveService.settingsBox.put('office_lat', lat);
    await hiveService.settingsBox.put('office_lng', lng);
    await hiveService.settingsBox.put('office_radius', radiusMeters);
  }

  @override
  Future<LocationResult> getCurrentLocation() async {
    double lat;
    double lng;

    switch (_mode) {
      case LocationSimulationMode.atOffice:
        // Exact office coordinates (0m from office, inside 200m)
        lat = _officeLat;
        lng = _officeLng;
        break;

      case LocationSimulationMode.outsideOffice:
        // ~1.5km north of office (outside 200m)
        lat = _officeLat + 0.0135;
        lng = _officeLng;
        break;

      case LocationSimulationMode.custom:
        lat = _customLat;
        lng = _customLng;
        break;

      case LocationSimulationMode.device:
        final position = await GeoUtils.getCurrentPosition();
        lat = position.latitude;
        lng = position.longitude;
        break;
    }

    final distance = GeoUtils.calculateDistanceInMeters(
      lat,
      lng,
      _officeLat,
      _officeLng,
    );

    final isWithin = distance <= _geofenceRadius;

    return LocationResult(
      latitude: lat,
      longitude: lng,
      distanceToOfficeMeters: distance,
      isWithinGeofence: isWithin,
      mode: _mode,
    );
  }
}
