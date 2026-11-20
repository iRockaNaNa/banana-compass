import 'package:banana_compass/models/weather_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeatherData.fromOpenMeteo', () {
    final json = <String, dynamic>{
      'current': {
        'temperature_2m': 30.0,
        'relative_humidity_2m': 50,
        'apparent_temperature': 32.0,
        'is_day': 1,
        'weather_code': 0,
        'wind_speed_10m': 18.0,
        'wind_direction_10m': 270,
        'pressure_msl': 1015.0,
        'visibility': 16000,
      },
      'hourly': {
        'time': ['2026-11-20T00:00', '2026-11-20T01:00'],
        'temperature_2m': [28.0, 27.0],
        'weather_code': [0, 1],
      },
    };

    test('parses current conditions', () {
      final data = WeatherData.fromOpenMeteo(json, 'Mesa');
      expect(data.cityName, 'Mesa');
      expect(data.current.temperatureC, 30.0);
      expect(data.current.apparentC, 32.0);
      expect(data.current.humidity, 50);
      expect(data.current.windSpeedKmh, 18.0);
      expect(data.current.windDirectionDeg, 270);
      expect(data.current.pressureHpa, 1015.0);
      expect(data.current.visibilityM, 16000);
      expect(data.current.isDay, isTrue);
      expect(data.current.description, 'Clear sky');
    });

    test('parses hourly points', () {
      final data = WeatherData.fromOpenMeteo(json, 'Mesa');
      expect(data.hourly, hasLength(2));
      expect(data.hourly[0].temperatureC, 28.0);
      expect(data.hourly[1].time.hour, 1);
    });

    test('computes dew point from temperature and humidity', () {
      // 30°C at 50% humidity: dew point is about 18.4°C.
      final data = WeatherData.fromOpenMeteo(json, 'Mesa');
      expect(data.current.dewPointC, closeTo(18.4, 0.5));
    });
  });

  group('dewPointCelsius', () {
    test('20°C at 50% humidity is about 9.3°C', () {
      expect(dewPointCelsius(20, 50), closeTo(9.3, 0.3));
    });

    test('no humidity data returns the temperature itself', () {
      expect(dewPointCelsius(20, 0), 20);
    });
  });

  group('weatherCodeDescription', () {
    test('covers the common codes', () {
      expect(weatherCodeDescription(0), 'Clear sky');
      expect(weatherCodeDescription(2), 'Partly cloudy');
      expect(weatherCodeDescription(61), 'Rain');
      expect(weatherCodeDescription(71), 'Snow');
      expect(weatherCodeDescription(95), 'Thunderstorm');
      expect(weatherCodeDescription(999), 'Unknown');
    });
  });

  group('AirQuality', () {
    test('parses pm2.5 and US AQI', () {
      final air = WeatherData.airQualityFromJson({
        'current': {'pm2_5': 12.3, 'us_aqi': 45},
      });
      expect(air, isNotNull);
      expect(air!.pm25, 12.3);
      expect(air.usAqi, 45);
      expect(air.label, 'Good');
    });

    test('labels the AQI bands', () {
      expect(const AirQuality(pm25: 5, usAqi: 30).label, 'Good');
      expect(const AirQuality(pm25: 20, usAqi: 80).label, 'Moderate');
      expect(
        const AirQuality(pm25: 60, usAqi: 130).label,
        'Unhealthy for sensitive groups',
      );
      expect(const AirQuality(pm25: 200, usAqi: 250).label, 'Very unhealthy');
    });

    test('returns null when the response is incomplete', () {
      expect(WeatherData.airQualityFromJson({}), isNull);
      expect(
        WeatherData.airQualityFromJson({
          'current': {'pm2_5': 12.3},
        }),
        isNull,
      );
    });
  });

  test('withAirQuality attaches air quality to weather', () {
    final data = WeatherData.fromOpenMeteo({
      'current': {
        'temperature_2m': 20.0,
        'relative_humidity_2m': 40,
        'apparent_temperature': 20.0,
        'is_day': 1,
        'weather_code': 1,
        'wind_speed_10m': 10.0,
        'wind_direction_10m': 180,
        'pressure_msl': 1013.0,
        'visibility': 10000,
      },
      'hourly': {'time': [], 'temperature_2m': [], 'weather_code': []},
    }, 'Mesa');
    final withAir = data.withAirQuality(
      const AirQuality(pm25: 8, usAqi: 25),
    );
    expect(withAir.airQuality, isNotNull);
    expect(withAir.current.temperatureC, 20.0);
  });
}
