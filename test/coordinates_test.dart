import 'package:banana_compass/utils/coordinates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatCoordinatePart', () {
    test('decimal degrees with hemisphere', () {
      expect(
        formatCoordinatePart(33.415, CoordFormat.dd, isLatitude: true),
        '33.41500° N',
      );
      expect(
        formatCoordinatePart(-111.657, CoordFormat.dd, isLatitude: false),
        '111.65700° W',
      );
      expect(
        formatCoordinatePart(0, CoordFormat.dd, isLatitude: true),
        '0.00000° N',
      );
    });

    test('degrees-minutes-seconds', () {
      // 33.415° = 33° 24′ 54″.
      expect(
        formatCoordinatePart(33.415, CoordFormat.dms, isLatitude: true),
        '33° 24′ 54″ N',
      );
      expect(
        formatCoordinatePart(-111.657, CoordFormat.dms, isLatitude: false),
        '111° 39′ 25″ W',
      );
    });

    test('degrees-decimal-minutes', () {
      expect(
        formatCoordinatePart(33.415, CoordFormat.ddm, isLatitude: true),
        '33° 24.900′ N',
      );
      expect(
        formatCoordinatePart(-111.657, CoordFormat.ddm, isLatitude: false),
        '111° 39.420′ W',
      );
    });
  });

  test('formatLatLon joins latitude and longitude', () {
    expect(
      formatLatLon(33.415, -111.657, CoordFormat.dd),
      '33.41500° N, 111.65700° W',
    );
  });

  test('degreesToMils uses the 6400-mil circle', () {
    expect(degreesToMils(0), 0);
    expect(degreesToMils(90), 1600);
    expect(degreesToMils(180), 3200);
    expect(degreesToMils(360), 6400);
    expect(degreesToMils(45), 800);
  });

  test('cardinalName gives the 16-wind point', () {
    expect(cardinalName(0), 'N');
    expect(cardinalName(22.5), 'NNE');
    expect(cardinalName(45), 'NE');
    expect(cardinalName(90), 'E');
    expect(cardinalName(135), 'SE');
    expect(cardinalName(180), 'S');
    expect(cardinalName(225), 'SW');
    expect(cardinalName(270), 'W');
    expect(cardinalName(315), 'NW');
    expect(cardinalName(359), 'N');
    expect(cardinalName(360), 'N');
  });
}
