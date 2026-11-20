/// Where level tilt readings come from, per platform.
///
/// Mobile: the accelerometer, through sensors_plus.
/// Web: the browser's DeviceOrientationEvent (beta/gamma) — mobile
/// browsers fire it; desktop browsers never do, so the level shows
/// "unavailable" there.
///
/// Picked at compile time by the conditional export, so the web build
/// never imports sensors_plus and the mobile build never imports
/// package:web. [TiltSource] itself lives in tilt_source_base.dart so
/// both branches — and the code that uses them — see the same type.
library;

export 'tilt_source_base.dart';
export 'tilt_source_io.dart'
    if (dart.library.js_interop) 'tilt_source_web.dart';
