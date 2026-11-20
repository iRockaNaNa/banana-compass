import 'package:material_ui/material_ui.dart';

import '../models/app_state.dart';
import '../models/settings.dart';
import '../models/weather_data.dart';
import '../services/premium.dart';
import '../services/purchase_service.dart';
import '../utils/coordinates.dart';
import '../widgets/hourly_chart.dart';
import 'paywall_screen.dart';

/// The weather tab: current conditions and the hourly forecast (free),
/// plus the advanced chart and extended metrics (Premium).
/// Weather comes from Open-Meteo for the GPS position — no API key,
/// and it works on web too.
class WeatherScreen extends StatelessWidget {
  const WeatherScreen({
    super.key,
    required this.settings,
    required this.purchaseService,
    required this.appState,
  });

  final AppSettings settings;
  final PurchaseService purchaseService;
  final AppState appState;

  double _displayTemp(double tempC) =>
      settings.useFahrenheit ? tempC * 9 / 5 + 32 : tempC;

  String _tempUnit() => settings.useFahrenheit ? '°F' : '°C';

  String _windSpeed(double kmh) => settings.useFahrenheit
      ? '${(kmh * 0.621371).round()} mph'
      : '${kmh.round()} km/h';

  String _visibility(double meters) {
    if (settings.useFeet) {
      return '${(meters * 3.28084 / 5280).toStringAsFixed(1)} mi';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final weather = appState.weather;
        return RefreshIndicator(
          onRefresh: () => appState.refreshWeather(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appState.weatherLoading && weather == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (weather == null)
                  _buildEmpty(context)
                else ...[
                  _buildCurrent(context, weather),
                  const SizedBox(height: 16),
                  _buildHourlyList(context, weather),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: purchaseService.isPremium,
                    builder: (context, isPremium, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildChartSection(context, weather, isPremium),
                          const SizedBox(height: 16),
                          _buildExtendedMetrics(context, weather, isPremium),
                        ],
                      );
                    },
                  ),
                ],
                if (appState.error != null && weather == null)
                  _buildError(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No weather yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              appState.error ??
                  'Turn on location to see the weather where you are.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => appState.refreshLocationAndWeather(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            appState.error ?? 'Weather unavailable.',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrent(BuildContext context, WeatherData weather) {
    final current = weather.current;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    weather.cityName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh weather',
                  onPressed: () => appState.refreshWeather(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_displayTemp(current.temperatureC).round()}${_tempUnit()}  •  '
              '${current.description}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _miniStat(
                  context,
                  Icons.air,
                  'Wind',
                  '${_windSpeed(current.windSpeedKmh)} ${cardinalName(current.windDirectionDeg)}',
                ),
                _miniStat(
                  context,
                  Icons.water_drop,
                  'Humidity',
                  '${current.humidity}%',
                ),
                _miniStat(
                  context,
                  Icons.speed,
                  'Pressure',
                  '${current.pressureHpa.round()} hPa',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(value, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildHourlyList(BuildContext context, WeatherData weather) {
    final hours = weather.hourly.take(12).toList();
    if (hours.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hourly',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: hours.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final h = hours[i];
                  return Column(
                    children: [
                      Text(
                        '${h.time.hour}:00',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_displayTemp(h.temperatureC).round()}°',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weatherCodeDescription(h.weatherCode),
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    WeatherData weather,
    bool isPremium,
  ) {
    final locked =
        PremiumRules.isChartsLocked(isPremium: isPremium);
    if (locked) {
      return _lockedCard(
        context,
        title: 'Advanced forecast chart',
        body: 'Premium shows the next 24 hours as a chart instead of a '
            'list.',
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Next 24 hours',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star, size: 16, color: Color(0xFFFFC107)),
              ],
            ),
            const SizedBox(height: 12),
            HourlyChart(
              hourly: weather.hourly,
              useFahrenheit: settings.useFahrenheit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtendedMetrics(
    BuildContext context,
    WeatherData weather,
    bool isPremium,
  ) {
    final locked = PremiumRules.isExtendedMetricsLocked(isPremium: isPremium);
    if (locked) {
      return _lockedCard(
        context,
        title: 'Extended metrics',
        body: 'Premium adds Feels Like, Dew Point, Visibility, and Air '
            'Quality.',
      );
    }
    final current = weather.current;
    final air = weather.airQuality;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Extended metrics',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star, size: 16, color: Color(0xFFFFC107)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                _metric(
                  'Feels Like',
                  '${_displayTemp(current.apparentC).round()}${_tempUnit()}',
                ),
                _metric(
                  'Dew Point',
                  '${_displayTemp(current.dewPointC).round()}${_tempUnit()}',
                ),
                _metric('Visibility', _visibility(current.visibilityM)),
                if (air != null)
                  _metric(
                    'Air Quality',
                    '${air.usAqi.round()} · ${air.label}',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _lockedCard(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lock, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => PaywallScreen.open(context, purchaseService),
              child: const Text('Go Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
