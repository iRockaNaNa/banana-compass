import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/settings.dart';
import '../utils/heading_math.dart';

/// The compass rose: a fixed dial (north up) with a needle that turns
/// to the heading, a lubber line at the top, and — for Premium — a wind
/// arrow on the rim showing where the wind is coming from.
///
/// The dial never rotates, so the cardinal letters stay upright and
/// readable; only the needle moves, like a real analog compass.
class CompassRose extends StatelessWidget {
  const CompassRose({
    super.key,
    required this.heading,
    required this.shape,
    required this.accent,
    this.windDirectionDeg,
    this.showWind = false,
    this.size = 320,
  });

  /// Heading in degrees (0 = north, clockwise). Null = no heading yet;
  /// the needle hides and the dial still draws.
  final double? heading;

  /// Which rose style to draw. Modern and Minimal are Premium.
  final CompassShape shape;

  /// Accent color (lime on dark, darker green on light).
  final Color accent;

  /// Wind direction in degrees (direction the wind comes FROM), from
  /// the weather service. Null when unknown.
  final double? windDirectionDeg;

  /// True when the wind arrow should draw (Premium + wind known).
  final bool showWind;

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RosePainter(
          heading: heading,
          shape: shape,
          accent: accent,
          windDirectionDeg: windDirectionDeg,
          showWind: showWind,
          textColor: Theme.of(context).colorScheme.onSurface,
          dimColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _RosePainter extends CustomPainter {
  _RosePainter({
    required this.heading,
    required this.shape,
    required this.accent,
    required this.windDirectionDeg,
    required this.showWind,
    required this.textColor,
    required this.dimColor,
  });

  final double? heading;
  final CompassShape shape;
  final Color accent;
  final double? windDirectionDeg;
  final bool showWind;
  final Color textColor;
  final Color dimColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring.
    final ringPaint = Paint()
      ..color = dimColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 2, ringPaint);
    canvas.drawCircle(center, radius * 0.62, ringPaint);

    // Tick marks.
    final minimal = shape == CompassShape.minimal;
    final step = minimal ? 30 : 10;
    for (var deg = 0; deg < 360; deg += step) {
      final isCardinal = deg % 90 == 0;
      final isIntercardinal = deg % 45 == 0;
      final isMajor = deg % 30 == 0;
      if (minimal && !isCardinal && !isIntercardinal) continue;
      final length = isCardinal
          ? radius * 0.10
          : isMajor
              ? radius * 0.07
              : radius * 0.04;
      final angle = toRadians(deg.toDouble());
      final outer = center +
          Offset(math.sin(angle), -math.cos(angle)) * (radius - 4);
      final inner = center +
          Offset(math.sin(angle), -math.cos(angle)) * (radius - 4 - length);
      final paint = Paint()
        ..color = isCardinal ? accent : dimColor
        ..strokeWidth = isCardinal ? 3 : 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(inner, outer, paint);
    }

    // Cardinal + intercardinal letters, always upright.
    final labels = {
      0: 'N',
      45: 'NE',
      90: 'E',
      135: 'SE',
      180: 'S',
      225: 'SW',
      270: 'W',
      315: 'NW',
    };
    for (final entry in labels.entries) {
      final angle = toRadians(entry.key.toDouble());
      final isCardinal = entry.key % 90 == 0;
      if (minimal && !isCardinal) continue;
      final distance = radius * (shape == CompassShape.modern ? 0.78 : 0.80);
      final pos = center +
          Offset(math.sin(angle), -math.cos(angle)) * distance;
      _drawText(
        canvas,
        entry.value,
        pos,
        TextStyle(
          color: entry.key == 0 ? accent : textColor,
          fontSize: isCardinal ? 22 : 15,
          fontWeight: isCardinal ? FontWeight.w800 : FontWeight.w600,
        ),
      );
    }

    // Modern shape: dot markers at the intercardinal points.
    if (shape == CompassShape.modern) {
      final dotPaint = Paint()..color = accent;
      for (var deg = 45; deg < 360; deg += 90) {
        final angle = toRadians(deg.toDouble());
        final pos = center +
            Offset(math.sin(angle), -math.cos(angle)) * radius * 0.62;
        canvas.drawCircle(pos, 4, dotPaint);
      }
    }

    // Wind arrow on the rim (Premium): points from the rim toward the
    // center, i.e. the direction the wind is blowing from.
    if (showWind && windDirectionDeg != null) {
      final angle = toRadians(windDirectionDeg!);
      final tip = center +
          Offset(math.sin(angle), -math.cos(angle)) * (radius - 14);
      final base = center +
          Offset(math.sin(angle), -math.cos(angle)) * (radius - 40);
      final arrowPaint = Paint()
        ..color = accent
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(base, tip, arrowPaint);
      // Arrowhead.
      final head = Path();
      final dir = (tip - base).normalize();
      final perp = Offset(-dir.dy, dir.dx);
      head.moveTo(tip.dx, tip.dy);
      head.lineTo(
        tip.dx - dir.dx * 10 + perp.dx * 6,
        tip.dy - dir.dy * 10 + perp.dy * 6,
      );
      head.lineTo(
        tip.dx - dir.dx * 10 - perp.dx * 6,
        tip.dy - dir.dy * 10 - perp.dy * 6,
      );
      head.close();
      canvas.drawPath(
        head,
        Paint()..color = accent,
      );
      _drawText(
        canvas,
        'WIND',
        center + Offset(math.sin(angle), -math.cos(angle)) * (radius - 56),
        TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    // Lubber line at the top (the heading marker).
    final lubberPaint = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, 2),
      Offset(center.dx, 16),
      lubberPaint,
    );

    // Needle: turns to the heading. North half accent, south half dim.
    if (heading != null) {
      final angle = toRadians(heading!);
      final dir = Offset(math.sin(angle), -math.cos(angle));
      final tip = center + dir * radius * 0.52;
      final tail = center - dir * radius * 0.34;
      final halfWidth = radius * 0.045;
      final perp = Offset(-dir.dy, dir.dx) * halfWidth;
      final needle = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tail.dx + perp.dx, tail.dy + perp.dy)
        ..lineTo(tail.dx - perp.dx, tail.dy - perp.dy)
        ..close();
      canvas.drawPath(needle, Paint()..color = accent);
      canvas.drawCircle(center, radius * 0.06, Paint()..color = textColor);
      canvas.drawCircle(
        center,
        radius * 0.03,
        Paint()..color = accent,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RosePainter old) =>
      old.heading != heading ||
      old.shape != shape ||
      old.accent != accent ||
      old.windDirectionDeg != windDirectionDeg ||
      old.showWind != showWind ||
      old.textColor != textColor;
}

extension on Offset {
  Offset normalize() {
    final len = distance;
    if (len == 0) return this;
    return this / len;
  }
}
