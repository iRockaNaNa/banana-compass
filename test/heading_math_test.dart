import 'package:banana_compass/utils/heading_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeHeading', () {
    test('wraps into 0..360', () {
      expect(normalizeHeading(0), 0);
      expect(normalizeHeading(370), 10);
      expect(normalizeHeading(360), 0);
      expect(normalizeHeading(-10), 350);
      expect(normalizeHeading(-370), 350);
    });
  });

  group('shortestArc', () {
    test('goes the short way around the circle', () {
      expect(shortestArc(350, 10), 20);
      expect(shortestArc(10, 350), -20);
      expect(shortestArc(0, 180), 180);
      expect(shortestArc(0, 190), -170);
      expect(shortestArc(90, 90), 0);
    });
  });

  group('headingDifference', () {
    test('is the smallest absolute gap', () {
      expect(headingDifference(359, 1), 2);
      expect(headingDifference(0, 180), 180);
      expect(headingDifference(45, 45), 0);
    });
  });

  group('smoothHeading', () {
    test('never spins the long way around', () {
      // 350 -> 10 should pass through 0, not through 180.
      expect(smoothHeading(350, 10, 0.5), 0);
      expect(smoothHeading(10, 350, 0.5), 0);
      expect(smoothHeading(350, 10, 1.0), 10);
      expect(smoothHeading(350, 10, 0.0), 350);
    });
  });

  group('declination conversion', () {
    test('magnetic + declination = true', () {
      // Mesa: magnetic 350 + declination ~10.2 = true ~0.2.
      expect(magneticToTrue(350, 10.2), closeTo(0.2, 0.001));
      expect(trueToMagnetic(0.2, 10.2), closeTo(350, 0.001));
      expect(magneticToTrue(0, 0), 0);
    });
  });

  test('deadband ignores sensor jitter', () {
    expect(deadband(100, 100.4, 1.0), 100);
    expect(deadband(100, 102, 1.0), 102);
  });
}
