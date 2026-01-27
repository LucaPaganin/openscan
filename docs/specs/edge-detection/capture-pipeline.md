# Capture Pipeline Skill

## Purpose

Process captured full-resolution images with independent edge detection and perspective correction. This pipeline is separate from preview detection and produces the final cropped document.

## Scope

- Full-resolution edge detection
- Independent detection (not relying on preview)
- Perspective transform (4-point warp)
- Output dimension calculation
- Manual corner adjustment support

## Key Concepts

### Why Separate Pipeline?

Preview detection:
- Runs on downscaled frames (480p)
- Prioritizes speed over accuracy
- Uses temporal filtering
- Results are approximate

Capture detection:
- Runs on full resolution (12MP+)
- Prioritizes accuracy
- Single-frame (no temporal context)
- Results must be precise for cropping

### Pipeline Flow

```
Captured Image (full-res)
        │
        ▼
   Edge Detection
   (independent from preview)
        │
        ▼
   ┌────┴────┐
   │         │
   ▼         ▼
 Found    Not Found
   │         │
   ▼         ▼
Perspective  Return for
 Transform   Manual Adjust
   │
   ▼
Cropped Document
```

### Perspective Transform

4-point perspective correction maps a quadrilateral to a rectangle:

```
Source (detected quad)          Destination (rectangle)
    A────────B                     A'───────B'
   /          \                    │         │
  /            \        ────▶      │         │
 /              \                  │         │
D────────────────C                 D'───────C'
```

## Implementation

### Capture Configuration

```dart
class CaptureDetectionConfig {
  // More relaxed thresholds for full-res
  final double cannyLow;
  final double cannyHigh;
  final double minAreaRatio;
  final double maxAreaRatio;
  
  // Morphological operations for gap closing
  final int dilateKernelSize;
  final int erodeKernelSize;

  const CaptureDetectionConfig({
    this.cannyLow = 30,
    this.cannyHigh = 100,
    this.minAreaRatio = 0.1,
    this.maxAreaRatio = 0.95,
    this.dilateKernelSize = 3,
    this.erodeKernelSize = 3,
  });
}
```

### Capture Result

```dart
/// Result of capture processing
sealed class CaptureResult {
  const CaptureResult();
}

class CaptureSuccess extends CaptureResult {
  final Uint8List originalImage;
  final Uint8List croppedImage;
  final DetectedQuad detectedQuad;
  final Size originalSize;
  final Size croppedSize;

  const CaptureSuccess({
    required this.originalImage,
    required this.croppedImage,
    required this.detectedQuad,
    required this.originalSize,
    required this.croppedSize,
  });
}

class CaptureManualRequired extends CaptureResult {
  final Uint8List originalImage;
  final Size originalSize;
  final String reason;
  final DetectedQuad? suggestedQuad; // Best guess, if any

  const CaptureManualRequired({
    required this.originalImage,
    required this.originalSize,
    required this.reason,
    this.suggestedQuad,
  });
}

class CaptureError extends CaptureResult {
  final String message;
  final Object? error;

  const CaptureError({
    required this.message,
    this.error,
  });
}
```

### Capture Detection Pipeline

```dart
import 'dart:isolate';
import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:image/image.dart' as img;

class CaptureDetectionPipeline {
  final CaptureDetectionConfig config;

  CaptureDetectionPipeline({
    this.config = const CaptureDetectionConfig(),
  });

  /// Process captured image - runs in isolate
  Future<CaptureResult> process(Uint8List imageBytes) async {
    return compute(_processInIsolate, _ProcessInput(imageBytes, config));
  }

  static CaptureResult _processInIsolate(_ProcessInput input) {
    try {
      // Decode image
      final image = img.decodeImage(input.imageBytes);
      if (image == null) {
        return CaptureError(message: 'Failed to decode image');
      }

      // Convert to grayscale OpenCV mat
      final grayscale = _imageToGrayscale(image);

      // Detect edges
      final quad = _detectQuad(grayscale, image.width, image.height, input.config);

      if (quad == null) {
        // Encode original for manual adjustment
        final encoded = img.encodeJpg(image, quality: 95);
        return CaptureManualRequired(
          originalImage: Uint8List.fromList(encoded),
          originalSize: Size(image.width.toDouble(), image.height.toDouble()),
          reason: 'Could not detect document edges',
        );
      }

      // Apply perspective transform
      final cropped = _perspectiveTransform(image, quad);

      // Encode results
      final originalEncoded = img.encodeJpg(image, quality: 95);
      final croppedEncoded = img.encodeJpg(cropped, quality: 95);

      return CaptureSuccess(
        originalImage: Uint8List.fromList(originalEncoded),
        croppedImage: Uint8List.fromList(croppedEncoded),
        detectedQuad: quad,
        originalSize: Size(image.width.toDouble(), image.height.toDouble()),
        croppedSize: Size(cropped.width.toDouble(), cropped.height.toDouble()),
      );
    } catch (e) {
      return CaptureError(message: 'Processing failed', error: e);
    }
  }

  static cv.Mat _imageToGrayscale(img.Image image) {
    final grayscale = img.grayscale(image);
    return cv.Mat.fromList(
      grayscale.height,
      grayscale.width,
      cv.MatType.CV_8UC1,
      grayscale.getBytes(),
    );
  }

  static DetectedQuad? _detectQuad(
    cv.Mat grayscale,
    int width,
    int height,
    CaptureDetectionConfig config,
  ) {
    // Blur
    final blurred = cv.Mat.empty();
    cv.GaussianBlur(grayscale, blurred, (5, 5), 0);

    // Canny edge detection
    final edges = cv.Mat.empty();
    cv.Canny(blurred, edges, config.cannyLow, config.cannyHigh);
    blurred.dispose();

    // Morphological operations to close gaps
    final kernel = cv.getStructuringElement(
      cv.MORPH_RECT,
      (config.dilateKernelSize, config.dilateKernelSize),
    );

    final dilated = cv.Mat.empty();
    cv.dilate(edges, dilated, kernel);

    final closed = cv.Mat.empty();
    cv.erode(dilated, closed, kernel);

    kernel.dispose();
    dilated.dispose();
    edges.dispose();

    // Find contours
    final contours = cv.Mat.empty();
    final hierarchy = cv.Mat.empty();
    cv.findContours(
      closed,
      contours,
      hierarchy,
      cv.RETR_EXTERNAL,
      cv.CHAIN_APPROX_SIMPLE,
    );
    closed.dispose();

    // Find best quadrilateral
    final frameArea = width * height;
    DetectedQuad? bestQuad;
    double bestScore = 0;

    for (int i = 0; i < contours.length; i++) {
      final contour = contours.rowRange(i, i + 1);

      // Approximate to polygon
      final perimeter = cv.arcLength(contour, true);
      final epsilon = 0.02 * perimeter;
      final approx = cv.Mat.empty();
      cv.approxPolyDP(contour, approx, epsilon, true);

      if (approx.rows != 4) {
        approx.dispose();
        continue;
      }

      // Check convexity
      if (!cv.isContourConvex(approx)) {
        approx.dispose();
        continue;
      }

      // Check area
      final area = cv.contourArea(approx);
      final areaRatio = area / frameArea;
      if (areaRatio < config.minAreaRatio || areaRatio > config.maxAreaRatio) {
        approx.dispose();
        continue;
      }

      // Extract and order corners
      final points = <NormalizedPoint>[];
      for (int j = 0; j < 4; j++) {
        final x = approx.at<double>(j, 0);
        final y = approx.at<double>(j, 1);
        points.add(NormalizedPoint(x / width, y / height));
      }
      approx.dispose();

      final quad = orderCorners(points);

      // Score (simplified for capture - just area and rectangularity)
      final score = _scoreCaptureQuad(quad, areaRatio);

      if (score > bestScore) {
        bestScore = score;
        bestQuad = quad;
      }
    }

    contours.dispose();
    hierarchy.dispose();
    grayscale.dispose();

    // Require minimum score
    return bestScore > 0.5 ? bestQuad : null;
  }

  static double _scoreCaptureQuad(DetectedQuad quad, double areaRatio) {
    // Area score
    final areaScore = areaRatio > 0.3 ? 1.0 : areaRatio / 0.3;

    // Rectangularity
    double angleDeviation = 0;
    for (int i = 0; i < 4; i++) {
      angleDeviation += (quad.internalAngleAt(i) - 90).abs();
    }
    final rectScore = (1.0 - angleDeviation / 180).clamp(0.0, 1.0);

    return (areaScore + rectScore) / 2;
  }

  static img.Image _perspectiveTransform(img.Image source, DetectedQuad quad) {
    // Convert normalized to pixel coordinates
    final srcPoints = [
      Point(quad.topLeft.x * source.width, quad.topLeft.y * source.height),
      Point(quad.topRight.x * source.width, quad.topRight.y * source.height),
      Point(quad.bottomRight.x * source.width, quad.bottomRight.y * source.height),
      Point(quad.bottomLeft.x * source.width, quad.bottomLeft.y * source.height),
    ];

    // Calculate output dimensions (preserve aspect ratio)
    final topWidth = _distance(srcPoints[0], srcPoints[1]);
    final bottomWidth = _distance(srcPoints[3], srcPoints[2]);
    final leftHeight = _distance(srcPoints[0], srcPoints[3]);
    final rightHeight = _distance(srcPoints[1], srcPoints[2]);

    final outputWidth = ((topWidth + bottomWidth) / 2).round();
    final outputHeight = ((leftHeight + rightHeight) / 2).round();

    // Destination points (rectangle)
    final dstPoints = [
      Point(0, 0),
      Point(outputWidth.toDouble(), 0),
      Point(outputWidth.toDouble(), outputHeight.toDouble()),
      Point(0, outputHeight.toDouble()),
    ];

    // Compute transform matrix using OpenCV
    final srcMat = cv.Mat.fromList(4, 2, cv.MatType.CV_32FC1, [
      srcPoints[0].x, srcPoints[0].y,
      srcPoints[1].x, srcPoints[1].y,
      srcPoints[2].x, srcPoints[2].y,
      srcPoints[3].x, srcPoints[3].y,
    ].map((e) => e.toDouble()).toList());

    final dstMat = cv.Mat.fromList(4, 2, cv.MatType.CV_32FC1, [
      dstPoints[0].x, dstPoints[0].y,
      dstPoints[1].x, dstPoints[1].y,
      dstPoints[2].x, dstPoints[2].y,
      dstPoints[3].x, dstPoints[3].y,
    ].map((e) => e.toDouble()).toList());

    final matrix = cv.getPerspectiveTransform(srcMat, dstMat);

    // Convert source image to OpenCV mat
    final sourceMat = cv.Mat.fromList(
      source.height,
      source.width,
      cv.MatType.CV_8UC3,
      source.getBytes(order: img.ChannelOrder.rgb),
    );

    // Apply warp
    final resultMat = cv.Mat.empty();
    cv.warpPerspective(
      sourceMat,
      resultMat,
      matrix,
      (outputWidth, outputHeight),
    );

    // Convert back to image
    final resultImage = img.Image(width: outputWidth, height: outputHeight);
    final bytes = resultMat.data;
    for (int y = 0; y < outputHeight; y++) {
      for (int x = 0; x < outputWidth; x++) {
        final idx = (y * outputWidth + x) * 3;
        resultImage.setPixelRgb(x, y, bytes[idx], bytes[idx + 1], bytes[idx + 2]);
      }
    }

    // Cleanup
    srcMat.dispose();
    dstMat.dispose();
    matrix.dispose();
    sourceMat.dispose();
    resultMat.dispose();

    return resultImage;
  }

  static double _distance(Point a, Point b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }
}

class _ProcessInput {
  final Uint8List imageBytes;
  final CaptureDetectionConfig config;

  _ProcessInput(this.imageBytes, this.config);
}

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
}
```

### Manual Adjustment Support

```dart
/// Apply perspective transform with user-provided corners
class ManualCropProcessor {
  /// Process with manually adjusted corners
  Future<Uint8List> processWithCorners(
    Uint8List imageBytes,
    DetectedQuad quad,
  ) async {
    return compute(_processManual, _ManualInput(imageBytes, quad));
  }

  static Uint8List _processManual(_ManualInput input) {
    final image = img.decodeImage(input.imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final cropped = CaptureDetectionPipeline._perspectiveTransform(
      image,
      input.quad,
    );

    return Uint8List.fromList(img.encodeJpg(cropped, quality: 95));
  }
}

class _ManualInput {
  final Uint8List imageBytes;
  final DetectedQuad quad;

  _ManualInput(this.imageBytes, this.quad);
}
```

### Capture Orchestrator

```dart
/// Coordinates the full capture flow
class CaptureOrchestrator {
  final CaptureDetectionPipeline _pipeline;
  final CameraController _cameraController;

  CaptureOrchestrator({
    required CameraController cameraController,
    CaptureDetectionConfig config = const CaptureDetectionConfig(),
  })  : _cameraController = cameraController,
        _pipeline = CaptureDetectionPipeline(config: config);

  /// Capture and process image
  Future<CaptureResult> capture({
    FilteredQuadState? previewState,
  }) async {
    try {
      // Take picture
      final xFile = await _cameraController.takePicture();
      final imageBytes = await xFile.readAsBytes();

      // Process
      final result = await _pipeline.process(imageBytes);

      // Validate consistency with preview (optional logging)
      if (result is CaptureSuccess && previewState?.isLocked == true) {
        final distance = result.detectedQuad.distanceTo(previewState!.quad!);
        if (distance > 0.1) {
          // Log: "Capture detection differed significantly from preview"
          // This is informational, not an error
        }
      }

      return result;
    } catch (e) {
      return CaptureError(message: 'Capture failed', error: e);
    }
  }

  /// Reprocess with manual corners
  Future<Uint8List> reprocessWithCorners(
    Uint8List originalImage,
    DetectedQuad quad,
  ) async {
    final processor = ManualCropProcessor();
    return processor.processWithCorners(originalImage, quad);
  }
}
```

## Unit Tests

```dart
void main() {
  group('CaptureDetectionPipeline', () {
    test('detects clear document', () async {
      final imageBytes = await loadTestImage('clear_document.jpg');
      final pipeline = CaptureDetectionPipeline();

      final result = await pipeline.process(imageBytes);

      expect(result, isA<CaptureSuccess>());
      final success = result as CaptureSuccess;
      expect(success.croppedImage.isNotEmpty, isTrue);
    });

    test('returns manual required for unclear image', () async {
      final imageBytes = await loadTestImage('blurry_no_document.jpg');
      final pipeline = CaptureDetectionPipeline();

      final result = await pipeline.process(imageBytes);

      expect(result, isA<CaptureManualRequired>());
    });

    test('perspective transform produces rectangular output', () async {
      final imageBytes = await loadTestImage('skewed_document.jpg');
      final pipeline = CaptureDetectionPipeline();

      final result = await pipeline.process(imageBytes);

      expect(result, isA<CaptureSuccess>());
      final success = result as CaptureSuccess;

      // Verify output is roughly rectangular aspect ratio
      final aspectRatio = success.croppedSize.width / success.croppedSize.height;
      expect(aspectRatio, greaterThan(0.5));
      expect(aspectRatio, lessThan(2.0));
    });
  });

  group('ManualCropProcessor', () {
    test('applies user-defined corners', () async {
      final imageBytes = await loadTestImage('document.jpg');
      final manualQuad = DetectedQuad(
        topLeft: NormalizedPoint(0.1, 0.1),
        topRight: NormalizedPoint(0.9, 0.1),
        bottomRight: NormalizedPoint(0.9, 0.9),
        bottomLeft: NormalizedPoint(0.1, 0.9),
      );

      final processor = ManualCropProcessor();
      final result = await processor.processWithCorners(imageBytes, manualQuad);

      expect(result.isNotEmpty, isTrue);
    });
  });

  group('Perspective transform math', () {
    test('calculates correct output dimensions', () {
      // Square input should produce square output
      final quad = DetectedQuad(
        topLeft: NormalizedPoint(0, 0),
        topRight: NormalizedPoint(100, 0),
        bottomRight: NormalizedPoint(100, 100),
        bottomLeft: NormalizedPoint(0, 100),
      );

      final topWidth = _distance(
        Point(quad.topLeft.x, quad.topLeft.y),
        Point(quad.topRight.x, quad.topRight.y),
      );
      final leftHeight = _distance(
        Point(quad.topLeft.x, quad.topLeft.y),
        Point(quad.bottomLeft.x, quad.bottomLeft.y),
      );

      expect(topWidth, closeTo(100, 0.1));
      expect(leftHeight, closeTo(100, 0.1));
    });
  });
}

double _distance(Point a, Point b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return sqrt(dx * dx + dy * dy);
}
```

## Performance Considerations

| Operation | Expected Time | Notes |
|-----------|---------------|-------|
| Image decode | 50-200ms | Depends on image size |
| Edge detection | 100-500ms | Full resolution |
| Perspective warp | 100-300ms | Depends on output size |
| JPEG encode | 50-150ms | Quality 95 |
| **Total** | **300-1200ms** | Acceptable for post-capture |

## Common Pitfalls

1. **Using preview quad for crop** — Always re-detect on full-res image

2. **Memory during transform** — Large images can cause OOM; consider chunked processing

3. **Aspect ratio distortion** — Calculate output size from actual edge lengths

4. **JPEG artifacts** — Use high quality (95) for intermediate saves

5. **Isolate overhead** — `compute()` has ~5ms overhead; acceptable for capture

## Dependencies

- `opencv_dart` package
- `image` package (for decode/encode)
- `geometry-validation.md` (for `DetectedQuad`)

## Related Skills

- `contour-detection.md` — Similar detection logic, different parameters
- `auto-capture.md` — Triggers this pipeline
