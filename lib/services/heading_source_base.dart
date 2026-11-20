/// A source of compass headings: a stream of magnetic headings in
/// degrees (0 = north, clockwise), or null when no heading is available
/// (no magnetometer, sensor off, or — on web — a desktop browser).
abstract class HeadingSource {
  Stream<double?> get headings;

  /// False when this platform can never produce a heading.
  bool get isSupported;

  Future<void> dispose();
}
