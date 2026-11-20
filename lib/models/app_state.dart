import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/weather_data.dart';
import '../services/altitude_service.dart';
import '../services/compass_service.dart';
import '../services/level_service.dart';
import '../services/location_service.dart';
import '../services/weather_api.dart';

/// Shared state for the whole app: the GPS position, the weather for
/// that position, and the three sensor services. The tabs read this
/// through a [ChangeNotifier] so they stay in sync — the compass and
/// the weather screen never fetch the same location twice.
class AppState extends ChangeNotifier {
  AppState({
    LocationService? locationService,
    WeatherApi? weatherApi,
    CompassService? compassService,
    LevelService? levelService,
    AltitudeService? altitudeService,
  })  : locationService = locationService ?? LocationService(),
        weatherApi = weatherApi ?? WeatherApi(),
        compassService = compassService ?? CompassService(),
        levelService = levelService ?? LevelService(),
        altitudeService = altitudeService ?? AltitudeService();

  final LocationService locationService;
  final WeatherApi weatherApi;
  final CompassService compassService;
  final LevelService levelService;
  final AltitudeService altitudeService;

  /// Last known GPS position. Null until the first fix.
  Position? position;

  /// City name for the position, from reverse geocoding.
  String cityName = 'Current Location';

  /// Weather for the position. Null until the first fetch.
  WeatherData? weather;

  /// True while the weather is loading.
  bool weatherLoading = false;

  /// Plain-words reason the location or weather failed, if any.
  String? error;

  Timer? _weatherTimer;
  bool _started = false;

  /// First load: GPS fix, then weather for it. Never throws.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await refreshLocationAndWeather();
  }

  /// Re-reads the GPS position and the weather for it.
  Future<void> refreshLocationAndWeather() async {
    error = null;
    try {
      final pos = await locationService.getCurrentPosition();
      position = pos;
      compassService.updateLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      cityName = await weatherApi.reverseGeocode(
        pos.latitude,
        pos.longitude,
      );
      notifyListeners();
      await refreshWeather();
    } on LocationException catch (e) {
      error = e.message;
      notifyListeners();
    } catch (_) {
      error = 'Could not get your location. Try again.';
      notifyListeners();
    }
  }

  /// Re-fetches the weather for the last known position.
  Future<void> refreshWeather() async {
    final pos = position;
    if (pos == null) return;
    weatherLoading = true;
    notifyListeners();
    try {
      var data = await weatherApi.fetchWeather(
        latitude: pos.latitude,
        longitude: pos.longitude,
        cityName: cityName,
      );
      final airQuality = await weatherApi.fetchAirQuality(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      if (airQuality != null) data = data.withAirQuality(airQuality);
      weather = data;
      error = null;
    } on WeatherException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not reach the weather service. Check your connection.';
    }
    weatherLoading = false;
    notifyListeners();
  }

  /// Starts the weather auto-refresh timer. Normal refresh is hourly;
  /// fast refresh (Premium) is every 10 minutes.
  void startWeatherTimer({required bool fastRefresh}) {
    _weatherTimer?.cancel();
    _weatherTimer = Timer.periodic(
      Duration(minutes: fastRefresh ? 10 : 60),
      (_) => unawaited(refreshWeather()),
    );
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    compassService.dispose();
    levelService.dispose();
    altitudeService.dispose();
    super.dispose();
  }
}
