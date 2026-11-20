import 'dart:async';

import '../utils/tilt_math.dart';
import 'device_orientation_web.dart';
import 'tilt_source_base.dart';

/// The platform's tilt source. Web uses [WebTiltSource],
/// mobile uses [MobileTiltSource] (see tilt_source.dart).
TiltSource createTiltSource() => WebTiltSource();

/// Tilt from the browser's DeviceOrientationEvent (beta/gamma).
///
/// Mobile browsers fire the event as the device moves, so the level
/// works on a phone in the browser. Desktop browsers never fire it, so
/// the level shows "unavailable" there. Beta/gamma are gravity-based
/// even when the event isn't absolute, so no absolute check is needed
/// here (unlike the compass heading).
class WebTiltSource implements TiltSource {
  StreamSubscription<DeviceOrientationReading>? _subscription;
  StreamController<Tilt>? _controller;

  @override
  Stream<Tilt> get tilts {
    _controller ??= StreamController<Tilt>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
    return _controller!.stream;
  }

  void _start() {
    _subscription = WebDeviceOrientation.instance.readings.listen((reading) {
      if (reading.beta != null && reading.gamma != null) {
        _controller?.add(
          tiltFromDeviceOrientation(reading.beta!, reading.gamma!),
        );
      }
    });
  }

  Future<void> _stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  Future<void> dispose() async {
    await _stop();
    await _controller?.close();
  }
}
