import 'dart:async';

import '../utils/tilt_math.dart';
import 'tilt_source.dart';

/// One level reading for the bubble level screen.
class LevelState {
  const LevelState({
    required this.tilt,
    required this.available,
    required this.locked,
    required this.hasTare,
  });

  /// Tilt with the tare offset applied. (0, 0) when level.
  final Tilt tilt;

  /// False when the device can't produce tilt (desktop browser).
  final bool available;

  /// True when the measurement is frozen at the lock moment.
  final bool locked;

  /// True when a custom zero (tare) is set.
  final bool hasTare;
}

/// Bubble level state: live tilt from the accelerometer (mobile) or the
/// browser's DeviceOrientationEvent (web), with a custom zero (tare)
/// and a lock that freezes the reading.
class LevelService {
  LevelService({TiltSource? tiltSource})
      : _tiltSource = tiltSource ?? createTiltSource();

  final TiltSource _tiltSource;

  final _controller = StreamController<LevelState>.broadcast();
  StreamSubscription<Tilt>? _subscription;
  Timer? _unavailableTimer;

  Tilt _raw = const Tilt(pitch: 0, roll: 0);
  Tilt? _tare;
  bool _locked = false;
  Tilt? _lockedTilt;
  bool _started = false;
  bool _everReceived = false;

  /// Live level readings. The first event is the unavailable state if
  /// nothing arrives within 4 seconds (desktop browser).
  Stream<LevelState> get states {
    _start();
    return _controller.stream;
  }

  /// Sets the current tilt as zero — the surface under the phone now
  /// reads as level. Great for a table that isn't quite flat.
  void setTare() {
    _tare = _raw;
    _emit();
  }

  /// Clears the custom zero.
  void clearTare() {
    _tare = null;
    _emit();
  }

  /// Freezes the reading where it is. Tap again to resume.
  void toggleLock() {
    _locked = !_locked;
    if (_locked) _lockedTilt = _displayTilt();
    _emit();
  }

  Tilt _displayTilt() {
    if (_locked && _lockedTilt != null) return _lockedTilt!;
    final tilt = _tare == null ? _raw : _raw.applyTare(_tare!);
    return tilt;
  }

  void _start() {
    if (_started) return;
    _started = true;
    _subscription = _tiltSource.tilts.listen(
      _onTilt,
      onError: (_) => _emitUnavailable(),
    );
    _unavailableTimer = Timer(const Duration(seconds: 4), () {
      if (!_everReceived) _emitUnavailable();
    });
  }

  void _onTilt(Tilt tilt) {
    _everReceived = true;
    _unavailableTimer?.cancel();
    _raw = tilt;
    _emit();
  }

  void _emit() {
    _controller.add(LevelState(
      tilt: _displayTilt(),
      available: _everReceived,
      locked: _locked,
      hasTare: _tare != null,
    ));
  }

  void _emitUnavailable() {
    _controller.add(const LevelState(
      tilt: Tilt(pitch: 0, roll: 0),
      available: false,
      locked: false,
      hasTare: false,
    ));
  }

  Future<void> dispose() async {
    _unavailableTimer?.cancel();
    await _subscription?.cancel();
    await _tiltSource.dispose();
    await _controller.close();
  }
}
