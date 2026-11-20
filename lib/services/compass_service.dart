import 'dart:async';

import '../utils/heading_math.dart';
import 'declination.dart';
import 'heading_source.dart';

/// One smoothed compass reading.
class CompassReading {
  const CompassReading({
    required this.magneticHeading,
    required this.trueHeading,
    required this.declination,
    required this.headingAvailable,
  });

  /// Smoothed magnetic heading (0-360), null when no heading is
  /// available (no magnetometer, or a desktop browser).
  final double? magneticHeading;

  /// Magnetic heading corrected to True North with the local
  /// declination. Null when the heading is unavailable.
  final double? trueHeading;

  /// Local magnetic declination in degrees (east positive). 0 when the
  /// location isn't known yet.
  final double declination;

  /// False when the device can't produce a heading at all.
  final bool headingAvailable;
}

/// Turns raw magnetometer headings into a calm, smoothed compass
/// reading, with True North correction from the WMM2025 declination
/// model. Works on mobile and on web (mobile browsers); on a desktop
/// browser no headings ever arrive and the reading stays unavailable.
class CompassService {
  CompassService({HeadingSource? headingSource, double smoothing = 0.25})
      : _headingSource = headingSource ?? createHeadingSource(),
        _smoothing = smoothing.clamp(0.05, 1.0);

  final HeadingSource _headingSource;
  final double _smoothing;

  final _controller = StreamController<CompassReading>.broadcast();
  StreamSubscription<double?>? _subscription;
  Timer? _unavailableTimer;

  double? _smoothedMagnetic;
  double _declination = 0;
  bool _hasLocation = false;
  bool _started = false;

  /// Smoothed compass readings. The first event is the unavailable
  /// reading if nothing arrives within 5 seconds (desktop browser).
  Stream<CompassReading> get readings {
    _start();
    return _controller.stream;
  }

  /// Current local declination in degrees (east positive).
  double get declination => _declination;

  /// Recomputes the declination for the given location. Call when the
  /// GPS position is known (and again if the user moves far).
  void updateLocation({
    required double latitude,
    required double longitude,
  }) {
    _declination = MagneticDeclination.declination(
      latitude: latitude,
      longitude: longitude,
    );
    _hasLocation = true;
    _emit();
  }

  void _start() {
    if (_started) return;
    _started = true;
    _subscription = _headingSource.headings.listen(
      _onHeading,
      onError: (_) => _emitUnavailable(),
    );
    // Desktop web: no DeviceOrientationEvent ever arrives. Say so after
    // a few seconds instead of spinning forever.
    _unavailableTimer = Timer(const Duration(seconds: 5), () {
      if (_smoothedMagnetic == null) _emitUnavailable();
    });
  }

  void _onHeading(double? raw) {
    _unavailableTimer?.cancel();
    if (raw == null) {
      _emitUnavailable();
      return;
    }
    final normalized = normalizeHeading(raw);
    _smoothedMagnetic = _smoothedMagnetic == null
        ? normalized
        : smoothHeading(_smoothedMagnetic!, normalized, _smoothing);
    _emit();
  }

  void _emit() {
    if (_smoothedMagnetic == null) {
      _emitUnavailable();
      return;
    }
    final magnetic = _smoothedMagnetic!;
    _controller.add(CompassReading(
      magneticHeading: magnetic,
      trueHeading:
          magneticToTrue(magnetic, _hasLocation ? _declination : 0),
      declination: _hasLocation ? _declination : 0,
      headingAvailable: true,
    ));
  }

  void _emitUnavailable() {
    _controller.add(CompassReading(
      magneticHeading: null,
      trueHeading: null,
      declination: _hasLocation ? _declination : 0,
      headingAvailable: false,
    ));
  }

  Future<void> dispose() async {
    _unavailableTimer?.cancel();
    await _subscription?.cancel();
    await _headingSource.dispose();
    await _controller.close();
  }
}
