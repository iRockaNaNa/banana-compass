import 'package:flutter_compass/flutter_compass.dart';

import 'heading_source_base.dart';

/// The platform's heading source. Mobile uses [MobileHeadingSource],
/// web uses [WebHeadingSource] (see heading_source.dart).
HeadingSource createHeadingSource() => MobileHeadingSource();

/// Magnetometer headings from flutter_compass (Android/iOS only).
class MobileHeadingSource implements HeadingSource {
  @override
  bool get isSupported => true;

  @override
  Stream<double?> get headings {
    final events = FlutterCompass.events;
    if (events == null) return Stream<double?>.value(null);
    return events.map((event) => event.heading);
  }

  @override
  Future<void> dispose() async {}
}
