# Geometry Validation Skill

## Purpose

Implement core quadrilateral data structures with geometric validation. This is the foundation — all other skills depend on these types being correct.

## Scope

- `NormalizedPoint` — 2D point in normalized coordinates (0.0–1.0)
- `DetectedQuad` — Four corners with geometric properties
- Convexity validation
- Internal angle calculation
- Corner ordering
- Area and aspect ratio computation

## Key Concepts

### Normalized Coordinates

All coordinates use normalized values (0.0 to 1.0) relative to frame dimensions:
- Origin: top-left of frame
- X: 0.0 (left) to 1.0 (right)
- Y: 0.0 (top) to 1.0 (bottom)

This decouples geometry from resolution, making testing and coordinate transforms simpler.

### Corner Ordering Convention

Corners are **always** ordered clockwise starting from top-left:

```
[0] top-left -------- [1] top-right
      |                      |
      |                      |
[3] bottom-left ---- [2] bottom-right
```

This consistency is critical for:
- Coordinate transforms
- Perspective correction
- Interpolation between frames

## Implementation

### NormalizedPoint

```dart
import 'dart:math';

/// A point in normalized coordinates (0.0 to 1.0)
class NormalizedPoint {
  final double x;
  final double y;

  const NormalizedPoint(this.x, this.y);

  /// Euclidean distance to another point
  double distanceTo(NormalizedPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Linear interpolation toward another point
  /// t=0 returns this, t=1 returns other
  NormalizedPoint lerp(NormalizedPoint other, double t) {
    return NormalizedPoint(
      x + (other.x - x) * t,
      y + (other.y - y) * t,
    );
  }

  /// Vector subtraction
  NormalizedPoint operator -(NormalizedPoint other) {
    return NormalizedPoint(x - other.x, y - other.y);
  }

  /// Scalar multiplication
  NormalizedPoint operator *(double scalar) {
    return NormalizedPoint(x * scalar, y * scalar);
  }

  /// Vector addition
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
```

### DetectedQuad

```dart
/// A detected quadrilateral with consistent corner ordering
/// Corners: top-left, top-right, bottom-right, bottom-left
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

  /// Corners as list in standard order
  List<NormalizedPoint> get corners => [
        topLeft,
        topRight,
        bottomRight,
        bottomLeft,
      ];

  /// Check if quadrilateral is convex using cross product signs
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
          return false; // Sign change = concave
        }
      }
    }
    return true;
  }

  /// Calculate internal angle at corner index (0-3) in degrees
  double internalAngleAt(int index) {
    assert(index >= 0 && index < 4);

    final pts = corners;
    final prev = pts[(index + 3) % 4];
    final curr = pts[index];
    final next = pts[(index + 1) % 4];

    // Vectors from current corner to neighbors
    final v1x = prev.x - curr.x;
    final v1y = prev.y - curr.y;
    final v2x = next.x - curr.x;
    final v2y = next.y - curr.y;

    // Dot product and magnitudes
    final dot = v1x * v2x + v1y * v2y;
    final mag1 = sqrt(v1x * v1x + v1y * v1y);
    final mag2 = sqrt(v2x * v2x + v2y * v2y);

    if (mag1 == 0 || mag2 == 0) return 0;

    final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return acos(cosAngle) * 180 / pi;
  }

  /// All internal angles
  List<double> get internalAngles =>
      List.generate(4, (i) => internalAngleAt(i));

  /// Area as fraction of frame (0.0 to 1.0) using shoelace formula
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

  /// Aspect ratio (average width / average height)
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

  /// Average distance between corresponding corners
  double distanceTo(DetectedQuad other) {
    final otherCorners = other.corners;
    double sum = 0;
    for (int i = 0; i < 4; i++) {
      sum += corners[i].distanceTo(otherCorners[i]);
    }
    return sum / 4;
  }

  /// Interpolate between this quad and another
  DetectedQuad lerp(DetectedQuad other, double t) {
    return DetectedQuad(
      topLeft: topLeft.lerp(other.topLeft, t),
      topRight: topRight.lerp(other.topRight, t),
      bottomRight: bottomRight.lerp(other.bottomRight, t),
      bottomLeft: bottomLeft.lerp(other.bottomLeft, t),
    );
  }

  /// Centroid of the quadrilateral
  NormalizedPoint get center {
    final pts = corners;
    final cx = pts.map((p) => p.x).reduce((a, b) => a + b) / 4;
    final cy = pts.map((p) => p.y).reduce((a, b) => a + b) / 4;
    return NormalizedPoint(cx, cy);
  }
}
```

### Corner Ordering Utility

```dart
/// Orders arbitrary 4 points into standard quad order
/// (top-left, top-right, bottom-right, bottom-left)
DetectedQuad orderCorners(List<NormalizedPoint> points) {
  assert(points.length == 4);

  // Find centroid
  final cx = points.map((p) => p.x).reduce((a, b) => a + b) / 4;
  final cy = points.map((p) => p.y).reduce((a, b) => a + b) / 4;

  // Sort by angle from centroid (counter-clockwise from positive x-axis)
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
```

## Validation Functions

```dart
/// Validates a quad meets document detection requirements
class QuadValidator {
  final double minAngle;
  final double maxAngle;
  final double minAspectRatio;
  final double maxAspectRatio;
  final double minArea;
  final double maxArea;

  const QuadValidator({
    this.minAngle = 45,
    this.maxAngle = 135,
    this.minAspectRatio = 0.3,
    this.maxAspectRatio = 3.0,
    this.minArea = 0.15,
    this.maxArea = 0.85,
  });

  ValidationResult validate(DetectedQuad quad) {
    // Check convexity
    if (!quad.isConvex) {
      return ValidationResult.failed('Quadrilateral is not convex');
    }

    // Check angles
    for (int i = 0; i < 4; i++) {
      final angle = quad.internalAngleAt(i);
      if (angle < minAngle || angle > maxAngle) {
        return ValidationResult.failed(
          'Angle at corner $i ($angle°) outside range [$minAngle, $maxAngle]',
        );
      }
    }

    // Check aspect ratio
    final ar = quad.aspectRatio;
    if (ar < minAspectRatio || ar > maxAspectRatio) {
      return ValidationResult.failed(
        'Aspect ratio ($ar) outside range [$minAspectRatio, $maxAspectRatio]',
      );
    }

    // Check area
    final area = quad.area;
    if (area < minArea || area > maxArea) {
      return ValidationResult.failed(
        'Area ($area) outside range [$minArea, $maxArea]',
      );
    }

    return ValidationResult.passed();
  }
}

class ValidationResult {
  final bool isValid;
  final String? reason;

  const ValidationResult._(this.isValid, this.reason);
  
  factory ValidationResult.passed() => ValidationResult._(true, null);
  factory ValidationResult.failed(String reason) => ValidationResult._(false, reason);
}
```

## Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NormalizedPoint', () {
    test('distanceTo calculates Euclidean distance', () {
      final p1 = NormalizedPoint(0, 0);
      final p2 = NormalizedPoint(3, 4);
      expect(p1.distanceTo(p2), equals(5.0));
    });

    test('lerp interpolates correctly', () {
      final p1 = NormalizedPoint(0, 0);
      final p2 = NormalizedPoint(10, 10);
      
      expect(p1.lerp(p2, 0).x, equals(0));
      expect(p1.lerp(p2, 0.5).x, equals(5));
      expect(p1.lerp(p2, 1).x, equals(10));
    });
  });

  group('DetectedQuad convexity', () {
    test('perfect rectangle is convex', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.2, 0.2),
        topRight: NormalizedPoint(0.8, 0.2),
        bottomRight: NormalizedPoint(0.8, 0.8),
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );
      expect(quad.isConvex, isTrue);
    });

    test('trapezoid is convex', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.3, 0.2),
        topRight: NormalizedPoint(0.7, 0.2),
        bottomRight: NormalizedPoint(0.8, 0.8),
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );
      expect(quad.isConvex, isTrue);
    });

    test('concave quad (arrow shape) fails', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.2, 0.2),
        topRight: NormalizedPoint(0.8, 0.2),
        bottomRight: NormalizedPoint(0.5, 0.5), // pushed inward
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );
      expect(quad.isConvex, isFalse);
    });
  });

  group('DetectedQuad angles', () {
    test('rectangle has 90° angles', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.2, 0.2),
        topRight: NormalizedPoint(0.8, 0.2),
        bottomRight: NormalizedPoint(0.8, 0.8),
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );

      for (int i = 0; i < 4; i++) {
        expect(quad.internalAngleAt(i), closeTo(90, 0.01));
      }
    });

    test('trapezoid has non-90° angles', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.3, 0.2),
        topRight: NormalizedPoint(0.7, 0.2),
        bottomRight: NormalizedPoint(0.9, 0.8),
        bottomLeft: NormalizedPoint(0.1, 0.8),
      );

      // Top angles > 90°, bottom angles < 90°
      expect(quad.internalAngleAt(0), greaterThan(90));
      expect(quad.internalAngleAt(1), greaterThan(90));
      expect(quad.internalAngleAt(2), lessThan(90));
      expect(quad.internalAngleAt(3), lessThan(90));
    });
  });

  group('DetectedQuad area', () {
    test('unit square has area 1.0', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0, 0),
        topRight: NormalizedPoint(1, 0),
        bottomRight: NormalizedPoint(1, 1),
        bottomLeft: NormalizedPoint(0, 1),
      );
      expect(quad.area, closeTo(1.0, 0.001));
    });

    test('half-frame quad has area ~0.25', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.25, 0.25),
        topRight: NormalizedPoint(0.75, 0.25),
        bottomRight: NormalizedPoint(0.75, 0.75),
        bottomLeft: NormalizedPoint(0.25, 0.75),
      );
      expect(quad.area, closeTo(0.25, 0.001));
    });
  });

  group('Corner ordering', () {
    test('reorders shuffled corners correctly', () {
      final unordered = [
        NormalizedPoint(0.8, 0.8), // bottom-right
        NormalizedPoint(0.2, 0.2), // top-left
        NormalizedPoint(0.2, 0.8), // bottom-left
        NormalizedPoint(0.8, 0.2), // top-right
      ];

      final quad = orderCorners(unordered);

      // Verify order: TL, TR, BR, BL
      expect(quad.topLeft.x, closeTo(0.2, 0.01));
      expect(quad.topLeft.y, closeTo(0.2, 0.01));
      expect(quad.topRight.x, closeTo(0.8, 0.01));
      expect(quad.bottomRight.y, closeTo(0.8, 0.01));
    });
  });

  group('QuadValidator', () {
    final validator = QuadValidator();

    test('valid rectangle passes', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.2, 0.2),
        topRight: NormalizedPoint(0.8, 0.2),
        bottomRight: NormalizedPoint(0.8, 0.8),
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );
      expect(validator.validate(quad).isValid, isTrue);
    });

    test('concave quad fails', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.2, 0.2),
        topRight: NormalizedPoint(0.8, 0.2),
        bottomRight: NormalizedPoint(0.5, 0.5),
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );
      expect(validator.validate(quad).isValid, isFalse);
    });

    test('too small quad fails', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.45, 0.45),
        topRight: NormalizedPoint(0.55, 0.45),
        bottomRight: NormalizedPoint(0.55, 0.55),
        bottomLeft: NormalizedPoint(0.45, 0.55),
      );
      expect(validator.validate(quad).isValid, isFalse);
      expect(validator.validate(quad).reason, contains('Area'));
    });
  });
}
```

## Common Pitfalls

1. **Forgetting to handle degenerate quads** — Points can be collinear, creating zero-area shapes
2. **Angle calculation edge cases** — Zero-length edges cause division by zero
3. **Corner ordering assumptions** — Never assume input points are pre-ordered
4. **Floating point comparison** — Use `closeTo()` in tests, not exact equality

## Dependencies

None — this skill is self-contained.
