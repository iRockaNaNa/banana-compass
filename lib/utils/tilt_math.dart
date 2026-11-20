import 'dart:math' as math;

/// Tilt math for the bubble level. Pure Dart — covered by
/// test/tilt_math_test.dart.
///
/// Convention (both axes in degrees, 0 = perfectly level):
/// - [pitch]: tilt around the device's X axis — positive when the TOP
///   edge is high, negative when the top edge is low.
/// - [roll]: tilt around the device's Y axis — positive when the RIGHT
///   edge is high, negative when the right edge is low.
///
/// The bubble on screen moves toward the high side, like a real level.
class Tilt {
  const Tilt({required this.pitch, required this.roll});

  /// Front-back tilt in degrees. Positive = top edge high.
  final double pitch;

  /// Left-right tilt in degrees. Positive = right edge high.
  final double roll;

  /// Total tilt from level, 0..90 degrees.
  double get magnitude =>
      math.sqrt(pitch * pitch + roll * roll).clamp(0.0, 90.0);

  /// True when both axes are within [tolerance] degrees of level.
  bool isLevel({double tolerance = 1.0}) =>
      pitch.abs() <= tolerance && roll.abs() <= tolerance;

  /// Returns a copy with the tare offsets subtracted (custom zero).
  Tilt applyTare(Tilt tare) =>
      Tilt(pitch: pitch - tare.pitch, roll: roll - tare.roll);

  @override
  String toString() =>
      'Tilt(pitch: ${pitch.toStringAsFixed(1)}, '
      'roll: ${roll.toStringAsFixed(1)})';
}

/// Pitch/roll from a phone accelerometer reading (x, y, z in m/s²).
/// Phone flat face-up reads about (0, 0, +9.8) and gives (0, 0).
Tilt tiltFromAccelerometer(double x, double y, double z) {
  // Guard against a zero vector (no sensor): report level, not NaN.
  if ((x * x + y * y + z * z) < 0.01) return const Tilt(pitch: 0, roll: 0);
  final pitch = math.atan2(-y, z) * 180 / math.pi;
  final roll = math.atan2(-x, z) * 180 / math.pi;
  return Tilt(pitch: pitch, roll: roll);
}

/// Pitch/roll from a browser DeviceOrientationEvent (web, mobile browsers).
/// beta = front-to-back tilt (-180..180), gamma = left-to-right (-90..90).
/// Both are 0 when the phone lies flat face-up, matching the
/// accelerometer convention above. Desktop browsers never fire the event,
/// so this is only called when an event actually arrived.
Tilt tiltFromDeviceOrientation(double beta, double gamma) =>
    Tilt(pitch: beta, roll: gamma);
