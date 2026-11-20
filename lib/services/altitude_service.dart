import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One altitude reading: pressure and altitude together.
class AltitudeState {
  const AltitudeState({
    required this.pressureHpa,
    required this.altitudeM,
    required this.hasBarometer,
    required this.hasGps,
    required this.seaLevelPressureHpa,
  });

  /// Air pressure in hPa, from the barometer when available.
  final double? pressureHpa;

  /// Altitude in meters. From the barometer when available, else GPS.
  final double? altitudeM;

  /// True when the barometer is reporting.
  final bool hasBarometer;

  /// True when GPS altitude is available.
  final bool hasGps;

  /// Sea-level pressure used for the barometric altitude (hPa).
  final double seaLevelPressureHpa;
}

/// Altitude from the barometer (mobile) with GPS fallback, plus pressure.
///
/// The barometer gives the steadiest altitude: pressure changes with
/// height, and the ISA formula turns pressure into meters. Browsers
/// have no barometer API, so on web the altitude is GPS only. GPS
/// altitude is polled on a timer (60s normally, 10s with fast refresh).
class AltitudeService {
  AltitudeService();

  static const _defaultSeaLevelHpa = 1013.25;
  static const _seaLevelKey = 'altitude_sea_level_hpa';

  final _controller = StreamController<AltitudeState>.broadcast();
  StreamSubscription<BarometerEvent>? _barometerSubscription;
  Timer? _barometerTimer;
  Timer? _gpsTimer;

  double? _pressureHpa;
  double? _gpsAltitudeM;
  double _seaLevelHpa = _defaultSeaLevelHpa;
  bool _started = false;
  bool _fastRefresh = false;

  /// Live altitude readings.
  Stream<AltitudeState> get states {
    _start();
    return _controller.stream;
  }

  /// Sea-level pressure currently in use (hPa).
  double get seaLevelPressureHpa => _seaLevelHpa;

  /// Switches GPS polling between 60s (normal) and 10s (fast refresh,
  /// Premium). Takes effect on the next poll.
  void setFastRefresh(bool fast) {
    if (fast == _fastRefresh) return;
    _fastRefresh = fast;
    _restartGpsTimer();
  }

  /// Calibrates the barometer: tell it the true altitude where you are
  /// standing (from a map or a trail sign) and it works out the
  /// sea-level pressure from the current pressure.
  void calibrateToAltitude(double knownAltitudeM) {
    final pressure = _pressureHpa;
    if (pressure == null) return;
    final ratio = 1 - knownAltitudeM / 44330.0;
    if (ratio <= 0) return;
    _seaLevelHpa = pressure / math.pow(ratio, 5.255);
    _saveSeaLevel();
    _emit();
  }

  /// Sets the sea-level pressure directly (from a weather report).
  void setSeaLevelPressure(double hpa) {
    _seaLevelHpa = hpa;
    _saveSeaLevel();
    _emit();
  }

  void _start() {
    if (_started) return;
    _started = true;
    unawaited(_loadSeaLevel());
    if (!kIsWeb) {
      // sensors_plus has no web implementation; on web the barometer
      // is skipped entirely and GPS is the only altitude source.
      try {
        _barometerSubscription = barometerEventStream().listen(
          _onBarometer,
          onError: (_) => _barometerUnavailable(),
        );
        // No barometer on this phone: after 3 quiet seconds, fall
        // back to GPS instead of waiting forever.
        _barometerTimer = Timer(
          const Duration(seconds: 3),
          _barometerUnavailable,
        );
      } catch (_) {
        _barometerUnavailable();
      }
    }
    _restartGpsTimer();
    unawaited(_pollGps());
  }

  void _onBarometer(BarometerEvent event) {
    _barometerTimer?.cancel();
    _pressureHpa = event.pressure;
    _emit();
  }

  void _barometerUnavailable() {
    _barometerTimer?.cancel();
    _pressureHpa = null;
    _emit();
  }

  void _restartGpsTimer() {
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(
      Duration(seconds: _fastRefresh ? 10 : 60),
      (_) => unawaited(_pollGps()),
    );
  }

  Future<void> _pollGps() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _gpsAltitudeM = position.altitude;
      _emit();
    } catch (_) {
      // GPS stays on its last value; the barometer covers altitude.
    }
  }

  /// Barometric altitude from pressure, ISA formula.
  double? _barometricAltitudeM() {
    final pressure = _pressureHpa;
    if (pressure == null || pressure <= 0) return null;
    return 44330.0 * (1 - math.pow(pressure / _seaLevelHpa, 1 / 5.255));
  }

  void _emit() {
    final barometric = _barometricAltitudeM();
    _controller.add(AltitudeState(
      pressureHpa: _pressureHpa,
      altitudeM: barometric ?? _gpsAltitudeM,
      hasBarometer: _pressureHpa != null,
      hasGps: _gpsAltitudeM != null,
      seaLevelPressureHpa: _seaLevelHpa,
    ));
  }

  Future<void> _loadSeaLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _seaLevelHpa =
          prefs.getDouble(_seaLevelKey) ?? _defaultSeaLevelHpa;
      _emit();
    } catch (_) {
      // Default stands.
    }
  }

  Future<void> _saveSeaLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_seaLevelKey, _seaLevelHpa);
    } catch (_) {
      // Still applies for this session.
    }
  }

  Future<void> dispose() async {
    _barometerTimer?.cancel();
    _gpsTimer?.cancel();
    await _barometerSubscription?.cancel();
    await _controller.close();
  }
}
