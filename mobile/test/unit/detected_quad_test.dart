import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/features/scanner/domain/normalized_point.dart';
import 'package:openscan/features/scanner/domain/detected_quad.dart';
import 'package:openscan/features/scanner/domain/quad_validator.dart';

void main() {
  group('NormalizedPoint', () {
    test('distanceTo calculates Euclidean distance', () {
      final p1 = NormalizedPoint(0, 0);
      final p2 = NormalizedPoint(3, 4);
      expect(p1.distanceTo(p2), equals(5.0));
    });

    test('distanceTo returns 0 for same point', () {
      final p = NormalizedPoint(0.5, 0.5);
      expect(p.distanceTo(p), equals(0.0));
    });

    test('lerp interpolates correctly', () {
      final p1 = NormalizedPoint(0, 0);
      final p2 = NormalizedPoint(10, 10);

      final at0 = p1.lerp(p2, 0);
      expect(at0.x, equals(0));
      expect(at0.y, equals(0));

      final atHalf = p1.lerp(p2, 0.5);
      expect(atHalf.x, equals(5));
      expect(atHalf.y, equals(5));

      final at1 = p1.lerp(p2, 1);
      expect(at1.x, equals(10));
      expect(at1.y, equals(10));
    });

    test('operator - subtracts correctly', () {
      final result = NormalizedPoint(0.8, 0.6) - NormalizedPoint(0.3, 0.2);
      expect(result.x, closeTo(0.5, 0.001));
      expect(result.y, closeTo(0.4, 0.001));
    });

    test('operator * scales correctly', () {
      final result = NormalizedPoint(0.5, 0.3) * 2;
      expect(result.x, closeTo(1.0, 0.001));
      expect(result.y, closeTo(0.6, 0.001));
    });

    test('operator + adds correctly', () {
      final result = NormalizedPoint(0.3, 0.2) + NormalizedPoint(0.4, 0.5);
      expect(result.x, closeTo(0.7, 0.001));
      expect(result.y, closeTo(0.7, 0.001));
    });

    test('equality compares x and y', () {
      expect(NormalizedPoint(0.5, 0.5), equals(NormalizedPoint(0.5, 0.5)));
      expect(
        NormalizedPoint(0.5, 0.5),
        isNot(equals(NormalizedPoint(0.5, 0.6))),
      );
    });

    test('hashCode is consistent with equality', () {
      final a = NormalizedPoint(0.5, 0.5);
      final b = NormalizedPoint(0.5, 0.5);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString formats correctly', () {
      expect(NormalizedPoint(0.5, 0.3).toString(), 'NormalizedPoint(0.5, 0.3)');
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

    test('all angles sum to approximately 360°', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.3, 0.2),
        topRight: NormalizedPoint(0.7, 0.2),
        bottomRight: NormalizedPoint(0.9, 0.8),
        bottomLeft: NormalizedPoint(0.1, 0.8),
      );

      final sum = quad.internalAngles.reduce((a, b) => a + b);
      expect(sum, closeTo(360, 0.1));
    });

    test('degenerate edge returns 0° angle', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.5, 0.5), // same as topRight
        topRight: NormalizedPoint(0.5, 0.5),
        bottomRight: NormalizedPoint(0.8, 0.8),
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );

      expect(quad.internalAngleAt(0), equals(0));
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

    test('degenerate (zero-area) quad returns 0', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.5, 0.5),
        topRight: NormalizedPoint(0.5, 0.5),
        bottomRight: NormalizedPoint(0.5, 0.5),
        bottomLeft: NormalizedPoint(0.5, 0.5),
      );
      expect(quad.area, closeTo(0, 0.001));
    });
  });

  group('DetectedQuad aspectRatio', () {
    test('square has aspect ratio 1.0', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.2, 0.2),
        topRight: NormalizedPoint(0.8, 0.2),
        bottomRight: NormalizedPoint(0.8, 0.8),
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );
      expect(quad.aspectRatio, closeTo(1.0, 0.01));
    });

    test('wide rectangle has aspect ratio > 1', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.1, 0.3),
        topRight: NormalizedPoint(0.9, 0.3),
        bottomRight: NormalizedPoint(0.9, 0.7),
        bottomLeft: NormalizedPoint(0.1, 0.7),
      );
      expect(quad.aspectRatio, greaterThan(1.0));
    });

    test('tall rectangle has aspect ratio < 1', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.3, 0.1),
        topRight: NormalizedPoint(0.7, 0.1),
        bottomRight: NormalizedPoint(0.7, 0.9),
        bottomLeft: NormalizedPoint(0.3, 0.9),
      );
      expect(quad.aspectRatio, lessThan(1.0));
    });
  });

  group('DetectedQuad distanceTo', () {
    test('same quad has distance 0', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.2, 0.2),
        topRight: NormalizedPoint(0.8, 0.2),
        bottomRight: NormalizedPoint(0.8, 0.8),
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );
      expect(quad.distanceTo(quad), closeTo(0, 0.001));
    });

    test('shifted quad has positive distance', () {
      final q1 = DetectedQuad(
        topLeft: NormalizedPoint(0.2, 0.2),
        topRight: NormalizedPoint(0.8, 0.2),
        bottomRight: NormalizedPoint(0.8, 0.8),
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );
      final q2 = DetectedQuad(
        topLeft: NormalizedPoint(0.3, 0.3),
        topRight: NormalizedPoint(0.9, 0.3),
        bottomRight: NormalizedPoint(0.9, 0.9),
        bottomLeft: NormalizedPoint(0.3, 0.9),
      );
      expect(q1.distanceTo(q2), greaterThan(0));
    });
  });

  group('DetectedQuad lerp', () {
    test('lerp at 0 returns this quad', () {
      final q1 = DetectedQuad(
        topLeft: NormalizedPoint(0.2, 0.2),
        topRight: NormalizedPoint(0.8, 0.2),
        bottomRight: NormalizedPoint(0.8, 0.8),
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );
      final q2 = DetectedQuad(
        topLeft: NormalizedPoint(0.3, 0.3),
        topRight: NormalizedPoint(0.7, 0.3),
        bottomRight: NormalizedPoint(0.7, 0.7),
        bottomLeft: NormalizedPoint(0.3, 0.7),
      );

      final result = q1.lerp(q2, 0);
      expect(result.topLeft.x, closeTo(0.2, 0.001));
      expect(result.topLeft.y, closeTo(0.2, 0.001));
    });

    test('lerp at 1 returns other quad', () {
      final q1 = DetectedQuad(
        topLeft: NormalizedPoint(0.2, 0.2),
        topRight: NormalizedPoint(0.8, 0.2),
        bottomRight: NormalizedPoint(0.8, 0.8),
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );
      final q2 = DetectedQuad(
        topLeft: NormalizedPoint(0.3, 0.3),
        topRight: NormalizedPoint(0.7, 0.3),
        bottomRight: NormalizedPoint(0.7, 0.7),
        bottomLeft: NormalizedPoint(0.3, 0.7),
      );

      final result = q1.lerp(q2, 1);
      expect(result.topLeft.x, closeTo(0.3, 0.001));
      expect(result.topLeft.y, closeTo(0.3, 0.001));
    });
  });

  group('DetectedQuad center', () {
    test('center of symmetric quad is at center of frame', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.2, 0.2),
        topRight: NormalizedPoint(0.8, 0.2),
        bottomRight: NormalizedPoint(0.8, 0.8),
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );
      expect(quad.center.x, closeTo(0.5, 0.001));
      expect(quad.center.y, closeTo(0.5, 0.001));
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

      expect(quad.topLeft.x, closeTo(0.2, 0.01));
      expect(quad.topLeft.y, closeTo(0.2, 0.01));
      expect(quad.topRight.x, closeTo(0.8, 0.01));
      expect(quad.topRight.y, closeTo(0.2, 0.01));
      expect(quad.bottomRight.x, closeTo(0.8, 0.01));
      expect(quad.bottomRight.y, closeTo(0.8, 0.01));
      expect(quad.bottomLeft.x, closeTo(0.2, 0.01));
      expect(quad.bottomLeft.y, closeTo(0.8, 0.01));
    });

    test('already-ordered corners remain unchanged', () {
      final ordered = [
        NormalizedPoint(0.2, 0.2),
        NormalizedPoint(0.8, 0.2),
        NormalizedPoint(0.8, 0.8),
        NormalizedPoint(0.2, 0.8),
      ];

      final quad = orderCorners(ordered);

      expect(quad.topLeft.x, closeTo(0.2, 0.01));
      expect(quad.topLeft.y, closeTo(0.2, 0.01));
      expect(quad.bottomRight.x, closeTo(0.8, 0.01));
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
      final result = validator.validate(quad);
      expect(result.isValid, isTrue);
      expect(result.reason, isNull);
    });

    test('concave quad fails validation', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.2, 0.2),
        topRight: NormalizedPoint(0.8, 0.2),
        bottomRight: NormalizedPoint(0.5, 0.5),
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );
      final result = validator.validate(quad);
      expect(result.isValid, isFalse);
      expect(result.reason, contains('convex'));
    });

    test('too small quad fails validation', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.45, 0.45),
        topRight: NormalizedPoint(0.55, 0.45),
        bottomRight: NormalizedPoint(0.55, 0.55),
        bottomLeft: NormalizedPoint(0.45, 0.55),
      );
      final result = validator.validate(quad);
      expect(result.isValid, isFalse);
      expect(result.reason, contains('Area'));
    });

    test('too large quad fails validation', () {
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.02, 0.02),
        topRight: NormalizedPoint(0.98, 0.02),
        bottomRight: NormalizedPoint(0.98, 0.98),
        bottomLeft: NormalizedPoint(0.02, 0.98),
      );
      final result = validator.validate(quad);
      expect(result.isValid, isFalse);
      expect(result.reason, contains('Area'));
    });

    test('custom validator with relaxed constraints passes', () {
      final relaxed = QuadValidator(
        minArea: 0.01,
        maxArea: 0.99,
      );
      final smallQuad = DetectedQuad(
        topLeft: NormalizedPoint(0.45, 0.45),
        topRight: NormalizedPoint(0.55, 0.45),
        bottomRight: NormalizedPoint(0.55, 0.55),
        bottomLeft: NormalizedPoint(0.45, 0.55),
      );
      expect(relaxed.validate(smallQuad).isValid, isTrue);
    });

    test('extreme angle fails validation', () {
      // Very skewed quad with sharp angles
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0.1, 0.2),
        topRight: NormalizedPoint(0.9, 0.2),
        bottomRight: NormalizedPoint(0.99, 0.8),
        bottomLeft: NormalizedPoint(0.01, 0.8),
      );
      // All angles should still be within default range for a mild trapezoid
      // but let's use a strict validator
      final strict = QuadValidator(minAngle: 85, maxAngle: 95);
      final result = strict.validate(quad);
      expect(result.isValid, isFalse);
      expect(result.reason, contains('Angle'));
    });
  });
}
