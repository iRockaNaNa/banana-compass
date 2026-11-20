/// Coordinate formatting: decimal degrees, degrees-minutes-seconds,
/// degrees-decimal-minutes, plus NATO mils and 16-wind cardinal names.
/// Pure Dart — covered by test/coordinates_test.dart.
enum CoordFormat { dd, dms, ddm }

/// Formats one coordinate (latitude or longitude) in the chosen format.
/// [isLatitude] picks N/S vs E/W. Examples (33.415, latitude):
/// - dd:  `33.41500° N`
/// - dms: `33° 24′ 54″ N`
/// - ddm: `33° 24.900′ N`
String formatCoordinatePart(
  double value,
  CoordFormat format, {
  required bool isLatitude,
}) {
  final hemisphere = isLatitude
      ? (value >= 0 ? 'N' : 'S')
      : (value >= 0 ? 'E' : 'W');
  final abs = value.abs();
  switch (format) {
    case CoordFormat.dd:
      return '${abs.toStringAsFixed(5)}° $hemisphere';
    case CoordFormat.dms:
      var degrees = abs.floor();
      final minutesFull = (abs - degrees) * 60;
      var minutes = minutesFull.floor();
      var seconds = (minutesFull - minutes) * 60;
      // Carry rounding (59.96" -> 60" rolls into the next minute).
      if (seconds >= 59.95) {
        seconds = 0;
        minutes += 1;
      }
      if (minutes >= 60) {
        minutes = 0;
        degrees += 1;
      }
      return '$degrees° ${minutes.toString().padLeft(2, '0')}′ '
          '${seconds.toStringAsFixed(0).padLeft(2, '0')}″ $hemisphere';
    case CoordFormat.ddm:
      final degrees = abs.floor();
      final minutes = (abs - degrees) * 60;
      return '$degrees° ${minutes.toStringAsFixed(3)}′ $hemisphere';
  }
}

/// "33.41500° N, 111.65700° W" (format depends on [format]).
String formatLatLon(
  double latitude,
  double longitude,
  CoordFormat format,
) {
  final lat = formatCoordinatePart(latitude, format, isLatitude: true);
  final lon = formatCoordinatePart(longitude, format, isLatitude: false);
  return '$lat, $lon';
}

/// NATO mils: a full circle is 6400 mils. 0° = 0 mils, 90° = 1600 mils.
double degreesToMils(double degrees) => degrees * 6400 / 360;

/// 16-wind compass point for a heading: N, NNE, NE, ENE, E, ...
String cardinalName(double headingDegrees) {
  const names = [
    'N', 'NNE', 'NE', 'ENE',
    'E', 'ESE', 'SE', 'SSE',
    'S', 'SSW', 'SW', 'WSW',
    'W', 'WNW', 'NW', 'NNW',
  ];
  final normalized = ((headingDegrees % 360) + 360) % 360;
  final index = ((normalized + 11.25) / 22.5).floor() % 16;
  return names[index];
}
