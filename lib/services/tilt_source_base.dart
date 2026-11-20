import '../utils/tilt_math.dart';

/// A source of tilt readings for the bubble level.
abstract class TiltSource {
  Stream<Tilt> get tilts;

  Future<void> dispose();
}
