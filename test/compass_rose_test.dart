import 'package:banana_compass/models/settings.dart';
import 'package:banana_compass/widgets/compass_rose.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('CompassRose', () {
    testWidgets('renders the dial with a heading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassRose(
              heading: 45,
              shape: CompassShape.classic,
              accent: Color(0xFFC8FF00),
            ),
          ),
        ),
      );
      expect(find.byType(CompassRose), findsOneWidget);
    });

    testWidgets('renders without a heading (no sensor)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassRose(
              heading: null,
              shape: CompassShape.minimal,
              accent: Color(0xFFC8FF00),
            ),
          ),
        ),
      );
      expect(find.byType(CompassRose), findsOneWidget);
    });

    testWidgets('renders the Premium wind arrow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompassRose(
              heading: 90,
              shape: CompassShape.modern,
              accent: Color(0xFFC8FF00),
              windDirectionDeg: 270,
              showWind: true,
            ),
          ),
        ),
      );
      expect(find.byType(CompassRose), findsOneWidget);
    });
  });
}
