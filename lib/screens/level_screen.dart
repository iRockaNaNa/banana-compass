
import 'package:material_ui/material_ui.dart';

import '../services/level_service.dart';
import '../utils/tilt_math.dart';

/// The level tab: a bubble level with a custom zero (tare) and a lock.
/// On a desktop browser there is no tilt sensor, so it says so instead
/// of showing a still bubble.
class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key, required this.levelService});

  final LevelService levelService;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<LevelState>(
      stream: levelService.states,
      builder: (context, snapshot) {
        final state = snapshot.data;
        if (state == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!state.available) {
          return _buildUnavailable(context);
        }
        final tilt = state.tilt;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              _LevelDial(tilt: tilt, accent: scheme.primary),
              const SizedBox(height: 20),
              if (tilt.isLevel())
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LEVEL',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                )
              else
                Text(
                  'Pitch ${tilt.pitch.toStringAsFixed(1)}°  •  '
                  'Roll ${tilt.roll.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => levelService.setTare(),
                    icon: const Icon(Icons.adjust, size: 18),
                    label: Text(state.hasTare ? 'Re-zero' : 'Set zero'),
                  ),
                  if (state.hasTare)
                    OutlinedButton(
                      onPressed: () => levelService.clearTare(),
                      child: const Text('Clear zero'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => levelService.toggleLock(),
                    icon: Icon(
                      state.locked ? Icons.lock_open : Icons.lock,
                      size: 18,
                    ),
                    label: Text(state.locked ? 'Unlock' : 'Lock'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                state.locked
                    ? 'Locked — the reading is frozen.'
                    : state.hasTare
                        ? 'Custom zero is set. "Clear zero" goes back to '
                            'true level.'
                        : 'Lay the phone on the surface. "Set zero" makes '
                            'that surface read as level.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnavailable(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.balance,
              size: 64,
              color: scheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'No level sensor here',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'This browser can\'t sense tilt. Open Banana Compass on a '
              'phone — in the app or in a mobile browser — and the bubble '
              'level works there.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bubble dial: crosshair, target rings, and a bubble that slides
/// toward the high side. 1 degree of tilt moves the bubble 6 logical
/// pixels, clamped inside the dial.
class _LevelDial extends StatelessWidget {
  const _LevelDial({required this.tilt, required this.accent});

  final Tilt tilt;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: _LevelDialPainter(tilt: tilt, accent: accent),
      ),
    );
  }
}

class _LevelDialPainter extends CustomPainter {
  _LevelDialPainter({required this.tilt, required this.accent});

  final Tilt tilt;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final ringPaint = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * 0.5, ringPaint);
    canvas.drawCircle(center, radius * 0.14, ringPaint);

    // Crosshair.
    final crossPaint = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      crossPaint,
    );

    // Bubble: moves toward the high side — right when the right edge
    // is high (roll +), up when the top edge is high (pitch +).
    const pixelsPerDegree = 6.0;
    final maxOffset = radius - 26;
    final dx = (tilt.roll * pixelsPerDegree).clamp(-maxOffset, maxOffset);
    final dy = (-tilt.pitch * pixelsPerDegree).clamp(-maxOffset, maxOffset);
    final bubbleCenter = center + Offset(dx, dy);
    canvas.drawCircle(
      bubbleCenter,
      24,
      Paint()..color = accent.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      bubbleCenter,
      24,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(bubbleCenter, 4, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _LevelDialPainter old) =>
      old.tilt.pitch != tilt.pitch || old.tilt.roll != tilt.roll;
}
