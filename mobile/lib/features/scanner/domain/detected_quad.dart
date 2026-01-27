import 'dart:math';

import 'normalized_point.dart';

/// A detected quadrilateral with consistent corner ordering.
///
/// Corners are always ordered clockwise starting from top-left:
/// ```
/// [topLeft] -------- [topRight]
///     |                   |
///     |                   |
/// [bottomLeft] ---- [bottomRight]
/// ```
class DetectedQuad {
  final NormalizedPoint topLeft;
  final NormalizedPoint topRight;
  final NormalizedPoint bottomRight;
  final NormalizedPoint bottomLeft;

  const DetectedQuad({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  /// Corners as list in standard order: TL, TR, BR, BL.
  List<NormalizedPoint> get corners => [
        topLeft,
        topRight,
        bottomRight,
        bottomLeft,
      ];

  /// Check if quadrilateral is convex using cross product signs.
  bool get isConvex {
    final pts = corners;
    int? expectedSign;

    for (int i = 0; i < 4; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % 4];
      final c = pts[(i + 2) % 4];

      // Cross product of vectors AB and BC
      final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);

      if (cross != 0) {
        final sign = cross > 0 ? 1 : -1;
        if (expectedSign == null) {
          expectedSign = sign;
        } else if (sign != expectedSign) {
          return false;
        }
      }
    }
    return true;
  }

  /// Calculate internal angle at corner index (0-3) in degrees.
  double internalAngleAt(int index) {
    assert(index >= 0 && index < 4);

    final pts = corners;
    final prev = pts[(index + 3) % 4];
    final curr = pts[index];
    final next = pts[(index + 1) % 4];

    final v1x = prev.x - curr.x;
    final v1y = prev.y - curr.y;
    final v2x = next.x - curr.x;
    final v2y = next.y - curr.y;

    final dot = v1x * v2x + v1y * v2y;
    final mag1 = sqrt(v1x * v1x + v1y * v1y);
    final mag2 = sqrt(v2x * v2x + v2y * v2y);

    if (mag1 == 0 || mag2 == 0) return 0;

    final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return acos(cosAngle) * 180 / pi;
  }

  /// All internal angles in degrees.
  List<double> get internalAngles =>
      List.generate(4, (i) => internalAngleAt(i));

  /// Area as fraction of frame (0.0 to 1.0) using the shoelace formula.
  double get area {
    final pts = corners;
    double sum = 0;
    for (int i = 0; i < 4; i++) {
      final j = (i + 1) % 4;
      sum += pts[i].x * pts[j].y;
      sum -= pts[j].x * pts[i].y;
    }
    return sum.abs() / 2;
  }

  /// Aspect ratio (average width / average height).
  double get aspectRatio {
    final topWidth = topLeft.distanceTo(topRight);
    final bottomWidth = bottomLeft.distanceTo(bottomRight);
    final leftHeight = topLeft.distanceTo(bottomLeft);
    final rightHeight = topRight.distanceTo(bottomRight);

    final avgWidth = (topWidth + bottomWidth) / 2;
    final avgHeight = (leftHeight + rightHeight) / 2;

    if (avgHeight == 0) return double.infinity;
    return avgWidth / avgHeight;
  }

  /// Average distance between corresponding corners of two quads.
  double distanceTo(DetectedQuad other) {
    final otherCorners = other.corners;
    double sum = 0;
    for (int i = 0; i < 4; i++) {
      sum += corners[i].distanceTo(otherCorners[i]);
    }
    return sum / 4;
  }

  /// Interpolate between this quad and another.
  DetectedQuad lerp(DetectedQuad other, double t) {
    return DetectedQuad(
      topLeft: topLeft.lerp(other.topLeft, t),
      topRight: topRight.lerp(other.topRight, t),
      bottomRight: bottomRight.lerp(other.bottomRight, t),
      bottomLeft: bottomLeft.lerp(other.bottomLeft, t),
    );
  }

  /// Centroid of the quadrilateral.
  NormalizedPoint get center {
    final pts = corners;
    final cx = pts.map((p) => p.x).reduce((a, b) => a + b) / 4;
    final cy = pts.map((p) => p.y).reduce((a, b) => a + b) / 4;
    return NormalizedPoint(cx, cy);
  }
}

/// Orders arbitrary 4 points into standard quad order
/// (top-left, top-right, bottom-right, bottom-left).
DetectedQuad orderCorners(List<NormalizedPoint> points) {
  assert(points.length == 4);

  // Find centroid
  final cx = points.map((p) => p.x).reduce((a, b) => a + b) / 4;
  final cy = points.map((p) => p.y).reduce((a, b) => a + b) / 4;

  // Sort by angle from centroid
  final sorted = List<NormalizedPoint>.from(points);
  sorted.sort((a, b) {
    final angleA = atan2(a.y - cy, a.x - cx);
    final angleB = atan2(b.y - cy, b.x - cx);
    return angleA.compareTo(angleB);
  });

  // Find top-left: smallest sum of x + y
  int topLeftIndex = 0;
  double minSum = double.infinity;
  for (int i = 0; i < 4; i++) {
    final sum = sorted[i].x + sorted[i].y;
    if (sum < minSum) {
      minSum = sum;
      topLeftIndex = i;
    }
  }

  // Rotate so top-left is first
  return DetectedQuad(
    topLeft: sorted[topLeftIndex],
    topRight: sorted[(topLeftIndex + 1) % 4],
    bottomRight: sorted[(topLeftIndex + 2) % 4],
    bottomLeft: sorted[(topLeftIndex + 3) % 4],
  );
}
