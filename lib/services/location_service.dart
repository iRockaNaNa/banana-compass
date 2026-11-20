import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// GPS location with friendly errors when permission is missing.
/// Works on mobile and on web (browser geolocation prompt).
class LocationService {
  /// Returns the device's current position, or throws [LocationException]
  /// with a plain-language reason.
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Location services are off. Turn them on to see your '
        'coordinates and weather.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Location permission was denied, so your coordinates can\'t '
          'be shown.',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission is off for this app. Enable it in Settings '
        'to see your coordinates and weather.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      throw LocationException(
        'Could not get your location. Check your connection and try again.',
      );
    }
  }

  /// Opens the app's system settings page (used from the error screen).
  /// On web this is a no-op — the browser permission lives in the
  /// browser's own site settings.
  Future<void> openAppSettings() => Geolocator.openAppSettings();
}
