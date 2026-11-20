import 'package:sensors_plus/sensors_plus.dart';

import '../utils/tilt_math.dart';
import 'tilt_source_base.dart';

/// The platform's tilt source. Mobile uses [MobileTiltSource],
/// web uses [WebTiltSource] (see tilt_source.dart).
TiltSource createTiltSource() => MobileTiltSource();

/// Tilt from the accelerometer (Android/iOS only).
/// sensors_plus has no web implementation, so this file is never
/// compiled for web.
class MobileTiltSource implements TiltSource {
  @override
  Stream<Tilt> get tilts => accelerometerEventStream().map(
        (event) => tiltFromAccelerometer(event.x, event.y, event.z),
      );

  @override
  Future<void> dispose() async {}
}
