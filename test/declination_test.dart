import 'package:banana_compass/services/declination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // WMM2025 declinations for 2026-01-01, cross-checked against the
  // independent pygeomag implementation (WMM-2025) to within 0.06 degrees,
  // and against published WMM2025 tables (e.g. London 1.1 E on 1 Jan 2026).
  // These values pin down the sign conventions: if Mesa came out -10
  // instead of +10, the east component would be backwards.
  group('MagneticDeclination', () {
    final date = DateTime(2026, 1, 1);

    test('Mesa, Arizona is about +10 degrees east', () {
      final d = MagneticDeclination.declination(
        latitude: 33.415,
        longitude: -111.657,
        date: date,
      );
      expect(d, closeTo(9.6, 0.5));
    });

    test('London is near zero', () {
      final d = MagneticDeclination.declination(
        latitude: 51.507,
        longitude: -0.128,
        date: date,
      );
      expect(d, closeTo(1.1, 0.5));
    });

    test('Sydney is about +13 degrees east', () {
      final d = MagneticDeclination.declination(
        latitude: -33.868,
        longitude: 151.209,
        date: date,
      );
      expect(d, closeTo(12.8, 0.5));
    });

    test('Tokyo is about -8 degrees (west)', () {
      final d = MagneticDeclination.declination(
        latitude: 35.676,
        longitude: 139.650,
        date: date,
      );
      expect(d, closeTo(-7.9, 0.5));
    });

    test('New York is about -13 degrees (west)', () {
      final d = MagneticDeclination.declination(
        latitude: 40.712,
        longitude: -74.006,
        date: date,
      );
      expect(d, closeTo(-12.5, 0.5));
    });

    test('Rio de Janeiro is about -22 degrees (west)', () {
      final d = MagneticDeclination.declination(
        latitude: -22.906,
        longitude: -43.172,
        date: date,
      );
      expect(d, closeTo(-23.0, 0.5));
    });

    test('Cape Town is about -26 degrees (west)', () {
      final d = MagneticDeclination.declination(
        latitude: -33.924,
        longitude: 18.424,
        date: date,
      );
      expect(d, closeTo(-26.6, 0.5));
    });

    test('declination is stable for a fixed date', () {
      final a = MagneticDeclination.declination(
        latitude: 33.415,
        longitude: -111.657,
        date: date,
      );
      final b = MagneticDeclination.declination(
        latitude: 33.415,
        longitude: -111.657,
        date: date,
      );
      expect(a, b);
    });
  });
}
