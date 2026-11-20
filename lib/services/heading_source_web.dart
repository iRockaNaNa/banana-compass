import 'dart:async';

import '../utils/heading_math.dart';
import 'device_orientation_web.dart';
import 'heading_source_base.dart';

/// The platform's heading source. Web uses [WebHeadingSource],
/// mobile uses [MobileHeadingSource] (see heading_source.dart).
HeadingSource createHeadingSource() => WebHeadingSource();

/// Compass heading from the browser's DeviceOrientationEvent.
///
/// Mobile browsers (Android Chrome, iOS Safari) fire the event with an
/// absolute compass heading in `alpha` when the device has a
/// magnetometer. Desktop browsers never fire the event at all, so the
/// stream simply stays quiet and the compass shows "unavailable" —
/// never a made-up heading.
///
/// Only events marked absolute are trusted: the plain
/// `deviceorientation` event can report alpha relative to wherever the
/// phone happened to be pointing when the page loaded.
class WebHeadingSource implements HeadingSource {
  StreamSubscription<DeviceOrientationReading>? _subscription;
  StreamController<double?>? _controller;

  @override
  bool get isSupported => true;

  @override
  Stream<double?> get headings {
    _controller ??= StreamController<double?>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
    return _controller!.stream;
  }

  void _start() {
    _subscription = WebDeviceOrientation.instance.readings.listen((reading) {
      if (reading.absolute && reading.alpha != null) {
        _controller?.add(normalizeHeading(reading.alpha!));
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
