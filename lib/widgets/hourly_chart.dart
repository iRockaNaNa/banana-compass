import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/weather_data.dart';

/// Advanced forecast chart (Premium): a line chart of the hourly
/// temperature for the next 24 hours, with dots and hour labels.
/// The free weather screen shows the same hours as a plain list instead.
class HourlyChart extends StatelessWidget {
  const HourlyChart({
    super.key,
    required this.hourly,
    required this.useFahrenheit,
    this.height = 140,
  });

  final List<HourlyPoint> hourly;
  final bool useFahrenheit;
  final double height;

  double _displayTemp(double tempC) =>
      useFahrenheit ? tempC * 9 / 5 + 32 : tempC;

  @override
  Widget build(BuildContext context) {
    final points = hourly.take(24).toList();
    if (points.length < 2) {
      return const SizedBox.shrink();
    }
    final minTemp = points
        .map((p) => _displayTemp(p.temperatureC))
        .reduce(math.min);
    final maxTemp = points
        .map((p) => _displayTemp(p.temperatureC))
        .reduce(math.max);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _HourlyChartPainter(
          points: points,
          minTemp: minTemp,
          maxTemp: maxTemp,
          useFahrenheit: useFahrenheit,
          lineColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onSurface,
          dimColor: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.55),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _HourlyChartPainter extends CustomPainter {
  _HourlyChartPainter({
    required this.points,
    required this.minTemp,
    required this.maxTemp,
    required this.useFahrenheit,
    required this.lineColor,
    required this.textColor,
    required this.dimColor,
  });

  final List<HourlyPoint> points;
  final double minTemp;
  final double maxTemp;
  final bool useFahrenheit;
  final Color lineColor;
  final Color textColor;
  final Color dimColor;

  double _temp(HourlyPoint p) =>
      useFahrenheit ? p.temperatureC * 9 / 5 + 32 : p.temperatureC;

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 18.0;
    final chartHeight = size.height - labelHeight - 8;
    final range = (maxTemp - minTemp).abs() < 0.5
        ? 1.0
        : (maxTemp - minTemp);
    final pad = range * 0.15;
    final low = minTemp - pad;
    final high = maxTemp + pad;

    Offset pointAt(int i) {
      final x = size.width * i / (points.length - 1);
      final t = _temp(points[i]);
      final y = 4 + chartHeight * (1 - (t - low) / (high - low));
      return Offset(x, y);
    }

    // Area fill under the line.
    final path = Path()..moveTo(0, 4 + chartHeight);
    for (var i = 0; i < points.length; i++) {
      final p = pointAt(i);
      if (i == 0) {
        path.lineTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.lineTo(size.width, 4 + chartHeight);
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = lineColor.withValues(alpha: 0.15),
    );

    // Line.
    final line = Path();
    for (var i = 0; i < points.length; i++) {
      final p = pointAt(i);
      if (i == 0) {
        line.moveTo(p.dx, p.dy);
      } else {
        line.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots + hour labels every 4 hours.
    for (var i = 0; i < points.length; i++) {
      final p = pointAt(i);
      canvas.drawCircle(p, 3, Paint()..color = lineColor);
      if (i % 4 == 0) {
        _drawText(
          canvas,
          '${points[i].time.hour}:00',
          Offset(p.dx, size.height - labelHeight + 2),
          TextStyle(color: dimColor, fontSize: 11),
        );
      }
    }

    // Min/max labels.
    _drawText(
      canvas,
      '${maxTemp.round()}°',
      Offset(4, 0),
      TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w700),
    );
    _drawText(
      canvas,
      '${minTemp.round()}°',
      Offset(4, 4 + chartHeight - 14),
      TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w700),
    );
  }

  void _drawText(Canvas canvas, String text, Offset pos, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _HourlyChartPainter old) =>
      old.points != points ||
      old.useFahrenheit != useFahrenheit ||
      old.lineColor != lineColor;
}
