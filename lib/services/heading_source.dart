/// Where compass headings come from, per platform.
///
/// Mobile (Android/iOS): the magnetometer, through flutter_compass.
/// Web: the browser's DeviceOrientationEvent — mobile browsers fire it
/// with a compass heading; desktop browsers never fire it, so the
/// compass shows "unavailable" there instead of a wrong heading.
///
/// The right implementation is picked at compile time by the
/// conditional export below, so the web build never imports
/// flutter_compass and the mobile build never imports package:web.
/// [HeadingSource] itself lives in heading_source_base.dart so both
/// branches — and the code that uses them — see the same type.
library;

export 'heading_source_base.dart';
export 'heading_source_io.dart'
    if (dart.library.js_interop) 'heading_source_web.dart';
