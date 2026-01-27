import 'detected_quad.dart';

/// Result of quadrilateral validation.
class ValidationResult {
  final bool isValid;
  final String? reason;

  const ValidationResult._(this.isValid, this.reason);

  factory ValidationResult.passed() => const ValidationResult._(true, null);
  factory ValidationResult.failed(String reason) =>
      ValidationResult._(false, reason);
}

/// Validates a quad meets document detection requirements.
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
    if (!quad.isConvex) {
      return ValidationResult.failed('Quadrilateral is not convex');
    }

    for (int i = 0; i < 4; i++) {
      final angle = quad.internalAngleAt(i);
      if (angle < minAngle || angle > maxAngle) {
        return ValidationResult.failed(
          'Angle at corner $i ($angle°) outside range [$minAngle, $maxAngle]',
        );
      }
    }

    final ar = quad.aspectRatio;
    if (ar < minAspectRatio || ar > maxAspectRatio) {
      return ValidationResult.failed(
        'Aspect ratio ($ar) outside range [$minAspectRatio, $maxAspectRatio]',
      );
    }

    final area = quad.area;
    if (area < minArea || area > maxArea) {
      return ValidationResult.failed(
        'Area ($area) outside range [$minArea, $maxArea]',
      );
    }

    return ValidationResult.passed();
  }
}
