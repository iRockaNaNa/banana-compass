import 'dart:math' as math;

/// Weather data from Open-Meteo (free, no API key), plus air quality
/// from Open-Meteo's air-quality API. Pure Dart — covered by
/// test/weather_data_test.dart.
///
/// Temperatures are stored in Celsius and wind in km/h; the UI converts
/// to Fahrenheit / mph when the user picks imperial units.
class CurrentWeather {
  const CurrentWeather({
    required this.temperatureC,
    required this.apparentC,
    required this.humidity,
    required this.dewPointC,
    required this.windSpeedKmh,
    required this.windDirectionDeg,
    required this.pressureHpa,
    required this.visibilityM,
    required this.weatherCode,
    required this.isDay,
  });

  final double temperatureC;
  final double apparentC;
  final int humidity;
  final double dewPointC;
  final double windSpeedKmh;
  final double windDirectionDeg;
  final double pressureHpa;
  final double visibilityM;
  final int weatherCode;
  final bool isDay;

  /// Plain-words label for the WMO weather code, e.g. "Clear sky".
  String get description => weatherCodeDescription(weatherCode);
}

class HourlyPoint {
  const HourlyPoint({
    required this.time,
    required this.temperatureC,
    required this.weatherCode,
  });

  final DateTime time;
  final double temperatureC;
  final int weatherCode;
}

class AirQuality {
  const AirQuality({required this.pm25, required this.usAqi});

  /// Fine particles, µg/m³.
  final double pm25;

  /// US Air Quality Index (0-500).
  final double usAqi;

  /// Plain-words label for the US AQI band.
  String get label {
    if (usAqi <= 50) return 'Good';
    if (usAqi <= 100) return 'Moderate';
    if (usAqi <= 150) return 'Unhealthy for sensitive groups';
    if (usAqi <= 200) return 'Unhealthy';
    if (usAqi <= 300) return 'Very unhealthy';
    return 'Hazardous';
  }
}

class WeatherData {
  const WeatherData({
    required this.cityName,
    required this.current,
    required this.hourly,
    this.airQuality,
  });

  final String cityName;
  final CurrentWeather current;
  final List<HourlyPoint> hourly;
  final AirQuality? airQuality;

  WeatherData withAirQuality(AirQuality value) => WeatherData(
        cityName: cityName,
        current: current,
        hourly: hourly,
        airQuality: value,
      );

  /// Parses an Open-Meteo forecast response (current + hourly).
  factory WeatherData.fromOpenMeteo(
    Map<String, dynamic> json,
    String cityName,
  ) {
    final current = json['current'] as Map<String, dynamic>;
    final tempC = (current['temperature_2m'] as num).toDouble();
    final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 0;
    final hourlyJson = json['hourly'] as Map<String, dynamic>? ?? {};
    final times = (hourlyJson['time'] as List?) ?? [];
    final temps = (hourlyJson['temperature_2m'] as List?) ?? [];
    final codes = (hourlyJson['weather_code'] as List?) ?? [];
    final hourly = <HourlyPoint>[];
    for (var i = 0; i < times.length && i < temps.length; i++) {
      final time = DateTime.tryParse(times[i] as String? ?? '');
      if (time == null) continue;
      hourly.add(HourlyPoint(
        time: time,
        temperatureC: (temps[i] as num).toDouble(),
        weatherCode: i < codes.length ? (codes[i] as num).toInt() : 0,
      ));
    }
    return WeatherData(
      cityName: cityName,
      current: CurrentWeather(
        temperatureC: tempC,
        apparentC: (current['apparent_temperature'] as num?)?.toDouble() ?? tempC,
        humidity: humidity,
        dewPointC: dewPointCelsius(tempC, humidity),
        windSpeedKmh:
            (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
        windDirectionDeg:
            (current['wind_direction_10m'] as num?)?.toDouble() ?? 0,
        pressureHpa: (current['pressure_msl'] as num?)?.toDouble() ?? 0,
        visibilityM: (current['visibility'] as num?)?.toDouble() ?? 0,
        weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
        isDay: (current['is_day'] as num?)?.toInt() == 1,
      ),
      hourly: hourly,
    );
  }

  /// Parses an Open-Meteo air-quality response (current pm2.5 + US AQI).
  static AirQuality? airQualityFromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>?;
    if (current == null) return null;
    final pm25 = (current['pm2_5'] as num?)?.toDouble();
    final aqi = (current['us_aqi'] as num?)?.toDouble();
    if (pm25 == null || aqi == null) return null;
    return AirQuality(pm25: pm25, usAqi: aqi);
  }
}

/// Dew point in Celsius from temperature and relative humidity,
/// Magnus formula. Returns the temperature itself when humidity is
/// missing or 0 (no moisture data).
double dewPointCelsius(double temperatureC, int humidity) {
  if (humidity <= 0) return temperatureC;
  const a = 17.27;
  const b = 237.7;
  final alpha =
      (a * temperatureC) / (b + temperatureC) + math.log(humidity / 100);
  return (b * alpha) / (a - alpha);
}

/// Plain-words label for a WMO weather code.
String weatherCodeDescription(int code) {
  return switch (code) {
    0 => 'Clear sky',
    1 => 'Mainly clear',
    2 => 'Partly cloudy',
    3 => 'Overcast',
    45 || 48 => 'Foggy',
    51 || 53 || 55 => 'Drizzle',
    56 || 57 => 'Freezing drizzle',
    61 || 63 || 65 => 'Rain',
    66 || 67 => 'Freezing rain',
    71 || 73 || 75 => 'Snow',
    77 => 'Snow grains',
    80 || 81 || 82 => 'Rain showers',
    85 || 86 => 'Snow showers',
    95 => 'Thunderstorm',
    96 || 99 => 'Thunderstorm with hail',
    _ => 'Unknown',
  };
}
