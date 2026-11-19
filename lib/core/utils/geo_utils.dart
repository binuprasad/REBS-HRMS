import 'package:geolocator/geolocator.dart';
import '../error/exceptions.dart';

class GeoUtils {
  /// Calculates distance in meters between two coordinates
  static double calculateDistanceInMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Checks if current location is within allowed radius (default 200m) of office
  static bool isWithinOfficeGeofence({
    required double currentLatitude,
    required double currentLongitude,
    required double officeLatitude,
    required double officeLongitude,
    double radiusMeters = 200.0,
  }) {
    final distance = calculateDistanceInMeters(
      currentLatitude,
      currentLongitude,
      officeLatitude,
      officeLongitude,
    );
    return distance <= radiusMeters;
  }

  /// Requests permission and retrieves current GPS position
  /// Handles:
  /// - Service disabled
  /// - Denied permission
  /// - Permanently denied permission
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'Location services are disabled on this device. Please turn on GPS.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          'Location permission was denied. Please allow location access to record attendance.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is permanently denied. Please enable it in device App Settings to proceed.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }
}
