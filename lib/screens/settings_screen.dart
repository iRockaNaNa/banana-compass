import 'package:material_ui/material_ui.dart';

import '../models/settings.dart';
import '../services/premium.dart';
import '../services/purchase_service.dart';
import '../utils/coordinates.dart';
import 'paywall_screen.dart';

/// Settings: theme, north mode, coordinate format, units, mils,
/// refresh rate, compass shape, and the Premium row. Premium-gated
/// rows show a lock and open the paywall when tapped.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.purchaseService,
  });

  final AppSettings settings;
  final PurchaseService purchaseService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: Listenable.merge([settings, purchaseService.isPremium]),
        builder: (context, _) {
          final isPremium = purchaseService.isPremium.value;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _sectionTitle(context, 'Premium'),
              _premiumRow(context, isPremium),
              _sectionTitle(context, 'Look'),
              _themeRow(context),
              _sectionTitle(context, 'Compass'),
              _northRow(context),
              _coordFormatRow(context),
              _switchRow(
                context,
                title: 'Show NATO mils',
                subtitle: '6400 mils around the dial, next to degrees.',
                value: settings.showMils,
                onChanged: (v) => settings.setShowMils(v),
              ),
              _shapeRow(context, isPremium),
              _sectionTitle(context, 'Units & refresh'),
              _unitsRow(context),
              _fastRefreshRow(context, isPremium),
              _sectionTitle(context, 'About'),
              _aboutCard(context),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: scheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _premiumRow(BuildContext context, bool isPremium) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(
          isPremium ? Icons.star : Icons.star_border,
          color: scheme.primary,
        ),
        title: Text(isPremium ? "You're Premium" : 'Go Premium'),
        subtitle: Text(
          isPremium
              ? 'Charts, compass shapes, wind on the rose, extended '
                  'metrics, and faster refresh are unlocked.'
              : 'Charts, compass shapes, wind on the rose, extended '
                  'metrics, and faster refresh.',
        ),
        trailing: isPremium ? null : const Icon(Icons.chevron_right),
        onTap: () => PaywallScreen.open(context, purchaseService),
      ),
    );
  }

  Widget _themeRow(BuildContext context) {
    return Card(
      child: RadioGroup<AppTheme>(
        groupValue: settings.theme,
        onChanged: (value) {
          if (value != null) settings.setTheme(value);
        },
        child: Column(
          children: [
            RadioListTile<AppTheme>(
              title: const Text('Dark'),
              subtitle: const Text(
                'Charcoal and lime — the Nanatech look.',
              ),
              value: AppTheme.dark,
            ),
            RadioListTile<AppTheme>(
              title: const Text('Light'),
              subtitle: const Text('For bright daylight.'),
              value: AppTheme.light,
            ),
            RadioListTile<AppTheme>(
              title: const Text('Pure AMOLED'),
              subtitle: const Text(
                'True black, saves battery on OLED screens.',
              ),
              value: AppTheme.amoled,
            ),
            RadioListTile<AppTheme>(
              title: const Text('Red Light'),
              subtitle: const Text(
                'Red on black — keeps your night vision.',
              ),
              value: AppTheme.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _northRow(BuildContext context) {
    return Card(
      child: RadioGroup<NorthMode>(
        groupValue: settings.northMode,
        onChanged: (value) {
          if (value != null) settings.setNorthMode(value);
        },
        child: Column(
          children: [
            RadioListTile<NorthMode>(
              title: const Text('True North'),
              subtitle: const Text(
                'The needle points at the geographic North Pole.',
              ),
              value: NorthMode.trueNorth,
            ),
            RadioListTile<NorthMode>(
              title: const Text('Magnetic North'),
              subtitle: const Text(
                'The needle points where a compass needle points.',
              ),
              value: NorthMode.magneticNorth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _coordFormatRow(BuildContext context) {
    return Card(
      child: RadioGroup<CoordFormat>(
        groupValue: settings.coordFormat,
        onChanged: (value) {
          if (value != null) settings.setCoordFormat(value);
        },
        child: Column(
          children: [
            RadioListTile<CoordFormat>(
              title: const Text('Decimal degrees'),
              subtitle: const Text('33.41500° N, 111.65700° W'),
              value: CoordFormat.dd,
            ),
            RadioListTile<CoordFormat>(
              title: const Text('Degrees, minutes, seconds'),
              subtitle: const Text('33° 24′ 54″ N, 111° 39′ 25″ W'),
              value: CoordFormat.dms,
            ),
            RadioListTile<CoordFormat>(
              title: const Text('Degrees, decimal minutes'),
              subtitle: const Text('33° 24.900′ N, 111° 39.420′ W'),
              value: CoordFormat.ddm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _shapeRow(BuildContext context, bool isPremium) {
    final shapesLocked =
        PremiumRules.isCompassShapesLocked(isPremium: isPremium);
    final classicTile = RadioListTile<CompassShape>(
      title: const Text('Classic rose'),
      subtitle: const Text('Ticks and letters — free.'),
      value: CompassShape.classic,
    );
    final modernTile = shapesLocked
        ? _lockedTile(
            context,
            title: 'Modern rose',
            subtitle: 'Dot markers and a bolder ring.',
          )
        : RadioListTile<CompassShape>(
            title: const Text('Modern rose'),
            subtitle: const Text('Dot markers and a bolder ring.'),
            value: CompassShape.modern,
          );
    final minimalTile = shapesLocked
        ? _lockedTile(
            context,
            title: 'Minimal rose',
            subtitle: 'Cardinals only, nothing extra.',
          )
        : RadioListTile<CompassShape>(
            title: const Text('Minimal rose'),
            subtitle: const Text('Cardinals only, nothing extra.'),
            value: CompassShape.minimal,
          );
    return Card(
      child: RadioGroup<CompassShape>(
        groupValue: settings.compassShape,
        onChanged: (value) {
          if (value != null) settings.setCompassShape(value);
        },
        child: Column(
          children: [classicTile, modernTile, minimalTile],
        ),
      ),
    );
  }

  /// A locked Premium row: a lock icon, and a tap opens the paywall.
  Widget _lockedTile(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.lock, size: 20),
      onTap: () => PaywallScreen.open(context, purchaseService),
    );
  }

  Widget _unitsRow(BuildContext context) {
    return Card(
      child: RadioGroup<Units>(
        groupValue: settings.units,
        onChanged: (value) {
          if (value != null) settings.setUnits(value);
        },
        child: Column(
          children: [
            RadioListTile<Units>(
              title: const Text('Metric'),
              subtitle: const Text('°C, km/h, meters.'),
              value: Units.metric,
            ),
            RadioListTile<Units>(
              title: const Text('Imperial'),
              subtitle: const Text('°F, mph, feet.'),
              value: Units.imperial,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fastRefreshRow(BuildContext context, bool isPremium) {
    final locked = PremiumRules.isFastRefreshLocked(isPremium: isPremium);
    return Card(
      child: ListTile(
        title: const Text('Faster refresh'),
        subtitle: Text(
          locked
              ? 'Premium: weather every 10 minutes instead of hourly, '
                  'GPS altitude every 10 seconds instead of 60.'
              : 'Weather every 10 minutes, GPS altitude every 10 seconds.',
        ),
        trailing: locked
            ? const Icon(Icons.lock)
            : Switch(
                value: settings.fastRefresh,
                onChanged: (v) => settings.setFastRefresh(v),
              ),
        onTap: locked
            ? () => PaywallScreen.open(context, purchaseService)
            : null,
      ),
    );
  }

  Widget _aboutCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Banana Compass 1.0.0',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Compass, level, altimeter, and weather — by Nanatech '
              'Creative Studios, Arizona, USA.',
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No ads, ever. Your location is processed on-device and '
              'never sent anywhere except the weather service, to fetch '
              'the forecast for where you are.',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
