import 'package:banana_compass/utils/tilt_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tiltFromAccelerometer', () {
    test('flat face-up reads level', () {
      final tilt = tiltFromAccelerometer(0, 0, 9.8);
      expect(tilt.pitch, closeTo(0, 0.001));
      expect(tilt.roll, closeTo(0, 0.001));
      expect(tilt.isLevel(), isTrue);
    });

    test('top edge up 30 degrees reads +30 pitch', () {
      // Top lifted 30°: ay = -g·sin30, az = g·cos30.
      final tilt = tiltFromAccelerometer(0, -4.9, 8.487);
      expect(tilt.pitch, closeTo(30, 0.1));
      expect(tilt.roll, closeTo(0, 0.1));
    });

    test('right edge up 30 degrees reads +30 roll', () {
      final tilt = tiltFromAccelerometer(-4.9, 0, 8.487);
      expect(tilt.roll, closeTo(30, 0.1));
      expect(tilt.pitch, closeTo(0, 0.1));
    });

    test('zero vector does not produce NaN', () {
      final tilt = tiltFromAccelerometer(0, 0, 0);
      expect(tilt.pitch, 0);
      expect(tilt.roll, 0);
    });
  });

  test('tiltFromDeviceOrientation maps beta/gamma to pitch/roll', () {
    final tilt = tiltFromDeviceOrientation(30, -10);
    expect(tilt.pitch, 30);
    expect(tilt.roll, -10);
  });

  test('Tilt.isLevel uses a 1 degree tolerance by default', () {
    expect(const Tilt(pitch: 0.5, roll: 0.5).isLevel(), isTrue);
    expect(const Tilt(pitch: 2, roll: 0).isLevel(), isFalse);
    expect(const Tilt(pitch: 0, roll: 0).isLevel(tolerance: 0.1), isTrue);
  });

  test('Tilt.applyTare subtracts the zero offset', () {
    const raw = Tilt(pitch: 10, roll: 5);
    const tare = Tilt(pitch: 10, roll: 5);
    final zeroed = raw.applyTare(tare);
    expect(zeroed.pitch, closeTo(0, 0.001));
    expect(zeroed.roll, closeTo(0, 0.001));
  });

  test('Tilt.magnitude is the total tilt from level', () {
    expect(const Tilt(pitch: 3, roll: 4).magnitude, closeTo(5, 0.001));
  });
}
