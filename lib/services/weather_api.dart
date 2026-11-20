import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_data.dart';

class WeatherException implements Exception {
  WeatherException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Open-Meteo — free weather data, no API key needed. Works on mobile
/// and on web (api.open-meteo.com allows browser requests).
class WeatherApi {
  WeatherApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _forecastBase = 'https://api.open-meteo.com/v1/forecast';
  static const _airQualityBase =
      'https://air-quality-api.open-meteo.com/v1/air-quality';

  /// Current weather + hourly forecast for a GPS point.
  Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    final uri = Uri.parse(
      '$_forecastBase?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
      'is_day,weather_code,wind_speed_10m,wind_direction_10m,'
      'pressure_msl,visibility'
      '&hourly=temperature_2m,weather_code'
      '&timezone=auto&forecast_days=3',
    );
    try {
      final res = await _client.get(uri).timeout(
            const Duration(seconds: 15),
          );
      if (res.statusCode != 200) {
        throw WeatherException(
          'Weather service returned ${res.statusCode}.',
        );
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return WeatherData.fromOpenMeteo(json, cityName);
    } on WeatherException {
      rethrow;
    } catch (_) {
      throw WeatherException(
        'Could not reach the weather service. Check your connection.',
      );
    }
  }

  /// Air quality for a GPS point (PM2.5 + US AQI). Null when the
  /// service can't answer — the weather still shows without it.
  Future<AirQuality?> fetchAirQuality({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      '$_airQualityBase?latitude=$latitude&longitude=$longitude'
      '&current=pm2_5,us_aqi',
    );
    try {
      final res = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return WeatherData.airQualityFromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Best-effort city name for GPS coordinates (BigDataCloud, free, no
  /// key). Falls back to "Current Location" when it can't be resolved.
  Future<String> reverseGeocode(double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.bigdatacloud.net/data/reverse-geocode-client'
      '?latitude=$lat&longitude=$lon&localityLanguage=en',
    );
    try {
      final res = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );
      if (res.statusCode != 200) return 'Current Location';
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final city = json['city'] as String?;
      final locality = json['locality'] as String?;
      final name = (city != null && city.isNotEmpty) ? city : locality;
      if (name == null || name.isEmpty) return 'Current Location';
      return name;
    } catch (_) {
      return 'Current Location';
    }
  }
}
