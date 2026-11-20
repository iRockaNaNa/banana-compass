import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// One shared DeviceOrientationEvent stream for the web build.
///
/// Both the compass heading and the level tilt come from the same
/// browser event, so this singleton registers the listeners once and
/// shares the readings. Mobile builds never import this file.
///
/// The event fires on mobile browsers when the device moves; desktop
/// browsers never fire it. `alpha` is the compass heading (only
/// meaningful when `absolute` is true), `beta` is the front-to-back
/// tilt, `gamma` the left-to-right tilt.
class DeviceOrientationReading {
  const DeviceOrientationReading({
    this.alpha,
    this.beta,
    this.gamma,
    required this.absolute,
  });

  /// Compass heading in degrees, 0 = north, clockwise. Null when the
  /// browser didn't provide one.
  final double? alpha;

  /// Front-to-back tilt in degrees (-180..180). 0 = flat face-up.
  final double? beta;

  /// Left-to-right tilt in degrees (-90..90). 0 = flat face-up.
  final double? gamma;

  /// True when alpha is a real compass heading. When false, alpha is
  /// relative to wherever the phone was pointing when the page loaded
  /// and must not be used as a compass.
  final bool absolute;
}

class WebDeviceOrientation {
  WebDeviceOrientation._();

  static final WebDeviceOrientation instance = WebDeviceOrientation._();

  StreamController<DeviceOrientationReading>? _controller;

  /// The converted listener is stored once so removeEventListener can
  /// actually remove the same function that was added.
  late final JSFunction _jsListener = _onEvent.toJS;

  Stream<DeviceOrientationReading> get readings {
    _controller ??= StreamController<DeviceOrientationReading>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
    return _controller!.stream;
  }

  void _start() {
    web.window.addEventListener('deviceorientationabsolute', _jsListener);
    web.window.addEventListener('deviceorientation', _jsListener);
  }

  void _stop() {
    web.window.removeEventListener('deviceorientationabsolute', _jsListener);
    web.window.removeEventListener('deviceorientation', _jsListener);
  }

  void _onEvent(web.Event event) {
    final e = event as web.DeviceOrientationEvent;
    _controller?.add(DeviceOrientationReading(
      alpha: e.alpha,
      beta: e.beta,
      gamma: e.gamma,
      absolute: e.absolute,
    ));
  }
}
