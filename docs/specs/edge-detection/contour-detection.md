# Contour Detection Skill

## Purpose

Implement the OpenCV-based detection pipeline that runs inside the isolate. This handles downscaling, edge detection, contour finding, filtering, and scoring.

## Scope

- Image downscaling for performance
- Gaussian blur preprocessing
- Canny edge detection with static thresholds
- Contour finding and polygon approximation
- Candidate filtering (area, convexity, angles)
- Quadrilateral scoring

## Key Concepts

### Pipeline Overview

```
Y-plane (grayscale) → Downscale → Blur → Canny → Contours → Filter → Score → Best
      input            480p       3×3    edges   all shapes  quads    rank   output
```

### Why This Order?

1. **Downscale first** — Processing 480p is 4-6x faster than 1080p
2. **Blur before Canny** — Reduces noise that creates spurious edges
3. **Static thresholds** — Adaptive thresholding is too slow for real-time
4. **Filter early** — Reject non-quads before expensive scoring

### Scoring Philosophy

The score combines:
- **Area coverage** — Documents typically fill 30-60% of frame
- **Rectangularity** — Internal angles close to 90°
- **Edge strength** — Detected edges align with contour
- **Stability bonus** — Reward quads near previous detection

## Implementation

### Pipeline Configuration

```dart
class ContourDetectionConfig {
  final int targetProcessingWidth;
  final int blurKernelSize;
  final double cannyLow;
  final double cannyHigh;
  final double minAreaRatio;
  final double maxAreaRatio;
  final double minAngle;
  final double maxAngle;
  final double minAspectRatio;
  final double maxAspectRatio;
  final double approxPolyEpsilon;

  const ContourDetectionConfig({
    this.targetProcessingWidth = 480,
    this.blurKernelSize = 3,
    this.cannyLow = 50,
    this.cannyHigh = 150,
    this.minAreaRatio = 0.15,
    this.maxAreaRatio = 0.85,
    this.minAngle = 45,
    this.maxAngle = 135,
    this.minAspectRatio = 0.3,
    this.maxAspectRatio = 3.0,
    this.approxPolyEpsilon = 0.02,
  });
}
```

### Score Breakdown

```dart
/// Detailed score breakdown for debugging
class QuadScoreBreakdown {
  final double areaScore;        // 0.0 - 1.0
  final double rectangularity;   // 0.0 - 1.0
  final double edgeStrength;     // 0.0 - 1.0
  final double stabilityBonus;   // 0.0 - 0.15

  const QuadScoreBreakdown({
    required this.areaScore,
    required this.rectangularity,
    required this.edgeStrength,
    this.stabilityBonus = 0,
  });

  /// Weighted total score
  double get total {
    const areaWeight = 0.25;
    const rectWeight = 0.35;
    const edgeWeight = 0.25;

    return (areaScore * areaWeight) +
        (rectangularity * rectWeight) +
        (edgeStrength * edgeWeight) +
        stabilityBonus;
  }
}

/// Scored candidate
class ScoredQuad {
  final DetectedQuad quad;
  final double score;
  final QuadScoreBreakdown breakdown;

  const ScoredQuad({
    required this.quad,
    required this.score,
    required this.breakdown,
  });
}
```

### Main Pipeline

```dart
import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class ContourDetectionPipeline {
  final ContourDetectionConfig config;
  
  // For stability bonus calculation
  DetectedQuad? _previousQuad;

  ContourDetectionPipeline({required this.config});

  /// Process a frame and return scored candidates
  List<ScoredQuad> process(Uint8List yPlane, int width, int height) {
    // 1. Create Mat from Y-plane
    final srcMat = cv.Mat.fromList(height, width, cv.MatType.CV_8UC1, yPlane);

    // 2. Downscale
    final scale = config.targetProcessingWidth / width;
    final targetHeight = (height * scale).round();
    final resized = cv.Mat.empty();
    cv.resize(srcMat, resized, (config.targetProcessingWidth, targetHeight),
        interpolation: cv.INTER_LINEAR);
    srcMat.dispose();

    // 3. Gaussian blur
    final blurred = cv.Mat.empty();
    cv.GaussianBlur(
      resized,
      blurred,
      (config.blurKernelSize, config.blurKernelSize),
      0,
    );
    resized.dispose();

    // 4. Canny edge detection
    final edges = cv.Mat.empty();
    cv.Canny(blurred, edges, config.cannyLow, config.cannyHigh);
    blurred.dispose();

    // 5. Find contours
    final contours = cv.Mat.empty();
    final hierarchy = cv.Mat.empty();
    cv.findContours(
      edges,
      contours,
      hierarchy,
      cv.RETR_EXTERNAL,
      cv.CHAIN_APPROX_SIMPLE,
    );

    // 6. Filter and score contours
    final frameArea = config.targetProcessingWidth * targetHeight;
    final candidates = <ScoredQuad>[];

    for (int i = 0; i < contours.length; i++) {
      final contour = contours.rowRange(i, i + 1);
      final scored = _evaluateContour(
        contour,
        frameArea,
        edges,
        config.targetProcessingWidth,
        targetHeight,
      );

      if (scored != null) {
        candidates.add(scored);
      }
    }

    // Cleanup
    edges.dispose();
    contours.dispose();
    hierarchy.dispose();

    // 7. Sort by score (descending)
    candidates.sort((a, b) => b.score.compareTo(a.score));

    // Update previous quad for next frame's stability bonus
    if (candidates.isNotEmpty) {
      _previousQuad = candidates.first.quad;
    }

    return candidates;
  }

  ScoredQuad? _evaluateContour(
    cv.Mat contour,
    int frameArea,
    cv.Mat edges,
    int frameWidth,
    int frameHeight,
  ) {
    // Approximate to polygon
    final perimeter = cv.arcLength(contour, true);
    final epsilon = config.approxPolyEpsilon * perimeter;
    final approx = cv.Mat.empty();
    cv.approxPolyDP(contour, approx, epsilon, true);

    // Must be quadrilateral (4 vertices)
    if (approx.rows != 4) {
      approx.dispose();
      return null;
    }

    // Extract points
    final points = <NormalizedPoint>[];
    for (int i = 0; i < 4; i++) {
      final x = approx.at<double>(i, 0);
      final y = approx.at<double>(i, 1);
      points.add(NormalizedPoint(x / frameWidth, y / frameHeight));
    }
    approx.dispose();

    // Order corners consistently
    final quad = orderCorners(points);

    // Check convexity
    if (!quad.isConvex) {
      return null;
    }

    // Check area
    final areaRatio = quad.area;
    if (areaRatio < config.minAreaRatio || areaRatio > config.maxAreaRatio) {
      return null;
    }

    // Check angles
    for (int i = 0; i < 4; i++) {
      final angle = quad.internalAngleAt(i);
      if (angle < config.minAngle || angle > config.maxAngle) {
        return null;
      }
    }

    // Check aspect ratio
    final aspectRatio = quad.aspectRatio;
    if (aspectRatio < config.minAspectRatio ||
        aspectRatio > config.maxAspectRatio) {
      return null;
    }

    // Calculate score
    final breakdown = _scoreQuad(quad, areaRatio, contour, edges);

    return ScoredQuad(
      quad: quad,
      score: breakdown.total,
      breakdown: breakdown,
    );
  }

  QuadScoreBreakdown _scoreQuad(
    DetectedQuad quad,
    double areaRatio,
    cv.Mat contour,
    cv.Mat edges,
  ) {
    // Area score: prefer 40-60% coverage
    // Score peaks at 0.5, drops off toward edges
    final idealArea = 0.5;
    final areaDelta = (areaRatio - idealArea).abs();
    final areaScore = (1.0 - areaDelta * 2).clamp(0.0, 1.0);

    // Rectangularity: how close angles are to 90°
    double totalDeviation = 0;
    for (int i = 0; i < 4; i++) {
      totalDeviation += (quad.internalAngleAt(i) - 90).abs();
    }
    // Max deviation is 4 * 45 = 180° (for trapezoidal shapes at limits)
    final rectangularity = (1.0 - totalDeviation / 180).clamp(0.0, 1.0);

    // Edge strength: sample edge pixels along contour
    final edgeStrength = _calculateEdgeStrength(contour, edges);

    // Stability bonus: reward quads near previous detection
    double stabilityBonus = 0;
    if (_previousQuad != null) {
      final distance = quad.distanceTo(_previousQuad!);
      // Closer = higher bonus, max 0.15
      stabilityBonus = (0.15 * (1.0 - distance * 5)).clamp(0.0, 0.15);
    }

    return QuadScoreBreakdown(
      areaScore: areaScore,
      rectangularity: rectangularity,
      edgeStrength: edgeStrength,
      stabilityBonus: stabilityBonus,
    );
  }

  double _calculateEdgeStrength(cv.Mat contour, cv.Mat edges) {
    int edgePixels = 0;
    int totalSamples = 0;

    // Sample along contour edges
    for (int i = 0; i < contour.rows; i++) {
      final x1 = contour.at<double>(i, 0).round();
      final y1 = contour.at<double>(i, 1).round();
      final x2 = contour.at<double>((i + 1) % contour.rows, 0).round();
      final y2 = contour.at<double>((i + 1) % contour.rows, 1).round();

      // Sample 10 points along each edge
      for (int j = 0; j <= 10; j++) {
        final t = j / 10;
        final x = (x1 + (x2 - x1) * t).round();
        final y = (y1 + (y2 - y1) * t).round();

        // Check bounds
        if (x >= 0 && x < edges.cols && y >= 0 && y < edges.rows) {
          if (edges.at<int>(y, x) > 0) {
            edgePixels++;
          }
          totalSamples++;
        }
      }
    }

    return totalSamples > 0 ? edgePixels / totalSamples : 0;
  }

  void reset() {
    _previousQuad = null;
  }
}
```

### Threshold Tuning Utilities

```dart
/// Preset configurations for different lighting conditions
class ThresholdPresets {
  /// Normal indoor lighting
  static const normal = ContourDetectionConfig(
    cannyLow: 50,
    cannyHigh: 150,
  );

  /// Bright, well-lit environment
  static const bright = ContourDetectionConfig(
    cannyLow: 80,
    cannyHigh: 200,
  );

  /// Dim lighting
  static const dim = ContourDetectionConfig(
    cannyLow: 30,
    cannyHigh: 100,
  );

  /// High contrast document (black text on white)
  static const highContrast = ContourDetectionConfig(
    cannyLow: 100,
    cannyHigh: 250,
  );
}

/// Adaptive threshold selector based on frame brightness
ContourDetectionConfig selectThresholds(Uint8List yPlane) {
  // Calculate mean brightness
  int sum = 0;
  for (final byte in yPlane) {
    sum += byte;
  }
  final meanBrightness = sum / yPlane.length;

  if (meanBrightness > 180) {
    return ThresholdPresets.bright;
  } else if (meanBrightness < 80) {
    return ThresholdPresets.dim;
  } else {
    return ThresholdPresets.normal;
  }
}
```

## Filtering Rules Summary

| Rule | Threshold | Rationale |
|------|-----------|-----------|
| Vertex count | exactly 4 | Must be quadrilateral |
| Convexity | must be convex | Concave shapes aren't documents |
| Area | 15% - 85% of frame | Too small = noise, too large = wall |
| Angles | 45° - 135° | Reasonable perspective distortion |
| Aspect ratio | 0.3 - 3.0 | Receipts to landscape documents |

## Scoring Weights

| Component | Weight | Rationale |
|-----------|--------|-----------|
| Area | 0.25 | Prefer well-framed documents |
| Rectangularity | 0.35 | Documents are usually rectangular |
| Edge strength | 0.25 | Detected edges should align with contour |
| Stability | 0.15 (bonus) | Reward consistent detections |

## Unit Tests

```dart
void main() {
  group('ContourDetectionPipeline', () {
    late ContourDetectionPipeline pipeline;

    setUp(() {
      pipeline = ContourDetectionPipeline(
        config: ContourDetectionConfig(),
      );
    });

    test('detects clear rectangle', () {
      // Create synthetic image with white rectangle on black background
      final image = createSyntheticImage(
        width: 640,
        height: 480,
        rectangleBounds: Rect.fromLTWH(100, 80, 440, 320),
      );

      final candidates = pipeline.process(image, 640, 480);

      expect(candidates, isNotEmpty);
      expect(candidates.first.score, greaterThan(0.7));
    });

    test('rejects concave shapes', () {
      // Create synthetic image with concave shape
      final image = createSyntheticConcaveShape();

      final candidates = pipeline.process(image, 640, 480);

      // Should filter out the concave shape
      expect(candidates, isEmpty);
    });

    test('rejects shapes too small', () {
      final image = createSyntheticImage(
        width: 640,
        height: 480,
        rectangleBounds: Rect.fromLTWH(300, 220, 40, 40), // 10% of frame
      );

      final candidates = pipeline.process(image, 640, 480);

      expect(candidates, isEmpty);
    });

    test('stability bonus increases for nearby quads', () {
      final image = createSyntheticImage(
        width: 640,
        height: 480,
        rectangleBounds: Rect.fromLTWH(100, 80, 440, 320),
      );

      // First frame
      final first = pipeline.process(image, 640, 480);
      final firstScore = first.first.score;

      // Second frame (same position)
      final second = pipeline.process(image, 640, 480);
      final secondScore = second.first.score;

      // Second should have stability bonus
      expect(secondScore, greaterThan(firstScore));
    });

    test('area score peaks at 50% coverage', () {
      final score30 = scoreAreaRatio(0.3);
      final score50 = scoreAreaRatio(0.5);
      final score70 = scoreAreaRatio(0.7);

      expect(score50, greaterThan(score30));
      expect(score50, greaterThan(score70));
    });

    test('rectangularity decreases with angle deviation', () {
      // Perfect rectangle
      final rect = DetectedQuad(
        topLeft: NormalizedPoint(0.2, 0.2),
        topRight: NormalizedPoint(0.8, 0.2),
        bottomRight: NormalizedPoint(0.8, 0.8),
        bottomLeft: NormalizedPoint(0.2, 0.8),
      );

      // Trapezoid
      final trap = DetectedQuad(
        topLeft: NormalizedPoint(0.3, 0.2),
        topRight: NormalizedPoint(0.7, 0.2),
        bottomRight: NormalizedPoint(0.9, 0.8),
        bottomLeft: NormalizedPoint(0.1, 0.8),
      );

      final rectScore = calculateRectangularity(rect);
      final trapScore = calculateRectangularity(trap);

      expect(rectScore, greaterThan(trapScore));
    });
  });
}

double scoreAreaRatio(double ratio) {
  const idealArea = 0.5;
  final delta = (ratio - idealArea).abs();
  return (1.0 - delta * 2).clamp(0.0, 1.0);
}

double calculateRectangularity(DetectedQuad quad) {
  double totalDeviation = 0;
  for (int i = 0; i < 4; i++) {
    totalDeviation += (quad.internalAngleAt(i) - 90).abs();
  }
  return (1.0 - totalDeviation / 180).clamp(0.0, 1.0);
}
```

## Performance Considerations

| Operation | Target Time | Notes |
|-----------|-------------|-------|
| Downscale | < 2ms | Use INTER_LINEAR, not INTER_CUBIC |
| Blur | < 2ms | 3×3 kernel is sufficient |
| Canny | < 5ms | Static thresholds, no auto-calculation |
| findContours | < 5ms | RETR_EXTERNAL reduces count |
| Scoring | < 5ms | Limited edge sampling |
| **Total** | **< 20ms** | Leaves headroom for isolate overhead |

## Common Pitfalls

1. **Using adaptive thresholding** — Too slow for real-time. Use static thresholds with presets.

2. **Processing full resolution** — Always downscale first. 480p is sufficient for detection.

3. **RETR_LIST vs RETR_EXTERNAL** — EXTERNAL returns only outer contours, reducing iterations.

4. **Forgetting Mat disposal** — OpenCV Mats must be manually disposed to avoid memory leaks.

5. **Edge strength sampling density** — 10 samples per edge is a balance between accuracy and speed.

## Dependencies

- `opencv_dart` package
- `geometry-validation.md` (for `DetectedQuad`, `NormalizedPoint`, `orderCorners`)

## Related Skills

- `isolate-pipeline.md` — Where this pipeline runs
- `temporal-filtering.md` — What consumes the output
