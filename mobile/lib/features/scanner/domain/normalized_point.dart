import 'dart:math';

/// A point in normalized coordinates (0.0 to 1.0).
///
/// Origin is top-left of the frame.
/// X: 0.0 (left) to 1.0 (right)
/// Y: 0.0 (top) to 1.0 (bottom)
class NormalizedPoint {
  final double x;
  final double y;

  const NormalizedPoint(this.x, this.y);

  /// Euclidean distance to another point.
  double distanceTo(NormalizedPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Linear interpolation toward another point.
  /// t=0 returns this, t=1 returns other.
  NormalizedPoint lerp(NormalizedPoint other, double t) {
    return NormalizedPoint(
      x + (other.x - x) * t,
      y + (other.y - y) * t,
    );
  }

  NormalizedPoint operator -(NormalizedPoint other) {
    return NormalizedPoint(x - other.x, y - other.y);
  }

  NormalizedPoint operator *(double scalar) {
    return NormalizedPoint(x * scalar, y * scalar);
  }

  NormalizedPoint operator +(NormalizedPoint other) {
    return NormalizedPoint(x + other.x, y + other.y);
  }

  @override
  bool operator ==(Object other) =>
      other is NormalizedPoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'NormalizedPoint($x, $y)';
}
