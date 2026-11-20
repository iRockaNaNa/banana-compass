import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../models/app_state.dart';
import '../models/settings.dart';
import '../services/altitude_service.dart';
import '../services/compass_service.dart';
import '../services/premium.dart';
import '../services/purchase_service.dart';
import '../utils/coordinates.dart';
import '../widgets/compass_rose.dart';

/// The compass tab: the rose, the heading in big numbers, coordinates,
/// and altitude + pressure. On a desktop browser there is no
/// magnetometer, so the rose draws without a needle and says so —
/// coordinates and weather still work there.
class CompassScreen extends StatelessWidget {
  const CompassScreen({
    super.key,
    required this.settings,
    required this.purchaseService,
    required this.appState,
  });

  final AppSettings settings;
  final PurchaseService purchaseService;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<CompassReading>(
      stream: appState.compassService.readings,
      builder: (context, snapshot) {
        final reading = snapshot.data;
        return ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  _buildNorthToggle(context),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: purchaseService.isPremium,
                    builder: (context, isPremium, _) {
                      final wind = appState.weather?.current;
                      return CompassRose(
                        heading: _displayHeading(reading),
                        shape: settings.compassShape,
                        accent: scheme.primary,
                        windDirectionDeg: wind?.windDirectionDeg,
                        showWind: isPremium &&
                            wind != null &&
                            !PremiumRules.isWindIndicatorLocked(
                              isPremium: isPremium,
                            ),
                        size: 300,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildHeadingReadout(context, reading),
                  const SizedBox(height: 16),
                  _buildCoordinatesCard(context),
                  const SizedBox(height: 12),
                  _buildAltitudeCard(context),
                  if (reading != null && !reading.headingAvailable)
                    _buildNoCompassCard(context),
                  if (appState.error != null &&
                      appState.position == null)
                    _buildLocationErrorCard(context),
                ],
              ),
            );
          },
        );
      },
    );
  }

  double? _displayHeading(CompassReading? reading) {
    if (reading == null || !reading.headingAvailable) return null;
    return settings.northMode == NorthMode.trueNorth
        ? reading.trueHeading
        : reading.magneticHeading;
  }

  Widget _buildNorthToggle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton(
            context,
            label: 'True North',
            selected: settings.northMode == NorthMode.trueNorth,
            onTap: () => settings.setNorthMode(NorthMode.trueNorth),
          ),
          _toggleButton(
            context,
            label: 'Magnetic',
            selected: settings.northMode == NorthMode.magneticNorth,
            onTap: () => settings.setNorthMode(NorthMode.magneticNorth),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? scheme.onPrimary : scheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildHeadingReadout(BuildContext context, CompassReading? reading) {
    final scheme = Theme.of(context).colorScheme;
    if (reading == null) {
      return const Text('Waiting for the compass…');
    }
    if (!reading.headingAvailable) {
      return Text(
        'No compass on this device',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      );
    }
    final heading = _displayHeading(reading)!;
    final northLabel =
        settings.northMode == NorthMode.trueNorth ? 'True' : 'Magnetic';
    return Column(
      children: [
        Text(
          '${heading.round()}° ${cardinalName(heading)}',
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          '$northLabel North'
          '${settings.showMils ? '  •  ${degreesToMils(heading).round()} mils' : ''}',
          style: TextStyle(fontSize: 15, color: scheme.onSurface.withValues(alpha: 0.7)),
        ),
        if (settings.northMode == NorthMode.trueNorth)
          Text(
            'Magnetic: ${reading.magneticHeading!.round()}°  •  '
            'Declination ${reading.declination >= 0 ? '+' : ''}'
            '${reading.declination.toStringAsFixed(1)}°',
            style: TextStyle(fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.6)),
          )
        else
          Text(
            'True: ${reading.trueHeading!.round()}°  •  '
            'Declination ${reading.declination >= 0 ? '+' : ''}'
            '${reading.declination.toStringAsFixed(1)}°',
            style: TextStyle(fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
      ],
    );
  }

  Widget _buildCoordinatesCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pos = appState.position;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.place, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appState.cityName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pos == null
                        ? 'Waiting for location…'
                        : formatLatLon(
                            pos.latitude,
                            pos.longitude,
                            settings.coordFormat,
                          ),
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh location',
              onPressed: () => appState.refreshLocationAndWeather(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAltitudeCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<AltitudeState>(
      stream: appState.altitudeService.states,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final altitude = state?.altitudeM;
        final pressure = state?.pressureHpa;
        final altitudeText = altitude == null
            ? '—'
            : settings.useFeet
                ? '${(altitude * 3.28084).round()} ft'
                : '${altitude.round()} m';
        final pressureText =
            pressure == null ? '—' : '${pressure.toStringAsFixed(1)} hPa';
        final source = state == null
            ? ''
            : state.hasBarometer
                ? 'Barometer'
                : state.hasGps
                    ? 'GPS'
                    : 'Waiting…';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.terrain, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Altitude  $altitudeText',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pressure $pressureText'
                        '${source.isNotEmpty ? '  •  $source' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                if (kIsWeb)
                  const Tooltip(
                    message: 'Web altitude comes from GPS — browsers '
                        'have no barometer.',
                    child: Icon(Icons.info_outline, size: 20),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoCompassCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.compass_calibration, color: scheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'This device has no compass sensor, so the needle '
                  'stays hidden. On a phone, hold it flat and move it '
                  'in a figure-8 to wake the sensor up. Coordinates, '
                  'altitude, and weather still work.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationErrorCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appState.error ?? 'Location unavailable.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => appState.refreshLocationAndWeather(),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
