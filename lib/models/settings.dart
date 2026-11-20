import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/coordinates.dart';

/// Look of the app. Dark is the default (Nanatech charcoal + lime).
enum AppTheme { dark, light, amoled, red }

/// Which north the compass needle points to.
enum NorthMode { trueNorth, magneticNorth }

/// Units for temperature, wind, and altitude.
enum Units { metric, imperial }

/// Compass rose style. Classic is free; Modern and Minimal are Premium.
enum CompassShape { classic, modern, minimal }

/// User settings, saved in SharedPreferences and shared with the whole
/// app through a [ChangeNotifier] so the theme and the compass update
/// the moment a setting changes.
class AppSettings extends ChangeNotifier {
  AppTheme theme = AppTheme.dark;
  NorthMode northMode = NorthMode.trueNorth;
  CoordFormat coordFormat = CoordFormat.dd;
  bool showMils = false;
  Units units = Units.metric;
  bool fastRefresh = false;
  CompassShape compassShape = CompassShape.classic;

  static const _themeKey = 'settings_theme';
  static const _northKey = 'settings_north';
  static const _coordKey = 'settings_coord_format';
  static const _milsKey = 'settings_show_mils';
  static const _unitsKey = 'settings_units';
  static const _fastRefreshKey = 'settings_fast_refresh';
  static const _shapeKey = 'settings_compass_shape';

  bool _loaded = false;

  /// True when the saved settings are Fahrenheit: [units] is imperial.
  bool get useFahrenheit => units == Units.imperial;

  /// True when altitudes show in feet: [units] is imperial.
  bool get useFeet => units == Units.imperial;

  /// Loads the saved settings. Never throws — a failure just keeps the
  /// defaults.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      theme = AppTheme.values[prefs.getInt(_themeKey) ?? 0];
      northMode = NorthMode.values[prefs.getInt(_northKey) ?? 0];
      coordFormat = CoordFormat.values[prefs.getInt(_coordKey) ?? 0];
      showMils = prefs.getBool(_milsKey) ?? false;
      units = Units.values[prefs.getInt(_unitsKey) ?? 0];
      fastRefresh = prefs.getBool(_fastRefreshKey) ?? false;
      compassShape = CompassShape.values[prefs.getInt(_shapeKey) ?? 0];
    } catch (_) {
      // Defaults stand.
    }
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, theme.index);
      await prefs.setInt(_northKey, northMode.index);
      await prefs.setInt(_coordKey, coordFormat.index);
      await prefs.setBool(_milsKey, showMils);
      await prefs.setInt(_unitsKey, units.index);
      await prefs.setBool(_fastRefreshKey, fastRefresh);
      await prefs.setInt(_shapeKey, compassShape.index);
    } catch (_) {
      // Settings still apply for this session.
    }
  }

  void setTheme(AppTheme value) {
    theme = value;
    _save();
    notifyListeners();
  }

  void setNorthMode(NorthMode value) {
    northMode = value;
    _save();
    notifyListeners();
  }

  void setCoordFormat(CoordFormat value) {
    coordFormat = value;
    _save();
    notifyListeners();
  }

  void setShowMils(bool value) {
    showMils = value;
    _save();
    notifyListeners();
  }

  void setUnits(Units value) {
    units = value;
    _save();
    notifyListeners();
  }

  void setFastRefresh(bool value) {
    fastRefresh = value;
    _save();
    notifyListeners();
  }

  void setCompassShape(CompassShape value) {
    compassShape = value;
    _save();
    notifyListeners();
  }
}
