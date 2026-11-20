import 'dart:math' as math;

/// Heading math on a circle: headings wrap at 360, so plain averaging
/// breaks (the average of 359 and 1 is 0, not 180). Pure Dart — covered
/// by test/heading_math_test.dart.

/// Wraps any angle to [0, 360).
double normalizeHeading(double degrees) {
  final wrapped = degrees % 360;
  return wrapped < 0 ? wrapped + 360 : wrapped;
}

/// Signed shortest turn from [from] to [to], in (-180, 180].
/// Positive means turn clockwise (heading increasing).
double shortestArc(double from, double to) {
  var diff = (to - from) % 360;
  if (diff > 180) diff -= 360;
  if (diff <= -180) diff += 360;
  return diff;
}

/// Smallest absolute difference between two headings, [0, 180].
double headingDifference(double a, double b) =>
    shortestArc(a, b).abs();

/// Moves [current] toward [target] by fraction [alpha] (0..1) along the
/// shortest arc, so a smoothed needle never spins the long way around.
/// [alpha] 1.0 means jump straight to the target; 0.25 is a calm needle.
double smoothHeading(double current, double target, double alpha) {
  final clamped = alpha.clamp(0.0, 1.0);
  return normalizeHeading(current + shortestArc(current, target) * clamped);
}

/// True heading from a magnetic heading and the local declination
/// (positive declination = Magnetic North east of True North).
/// true = magnetic + declination.
double magneticToTrue(double magneticHeading, double declination) =>
    normalizeHeading(magneticHeading + declination);

/// Magnetic heading from a true heading and the local declination.
double trueToMagnetic(double trueHeading, double declination) =>
    normalizeHeading(trueHeading - declination);

/// Back-and-forth shake filter: ignores raw jumps smaller than
/// [deadband] degrees (sensor noise), returns the current value instead.
double deadband(double current, double raw, double deadband) =>
    headingDifference(current, raw) < deadband ? current : raw;

/// Distance for the compass needle's "how far off north" readout.
double offNorth(double heading) => headingDifference(heading, 0);

/// Radians helper used by the rose painter.
double toRadians(double degrees) => degrees * math.pi / 180;
