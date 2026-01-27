# Coordinate Transform Skill

## Purpose

Transform detected quadrilateral coordinates from camera space to Flutter canvas space, handling device orientation, aspect ratio differences, and front camera mirroring.

## Scope

- Normalized coordinates to pixel coordinates
- Device orientation compensation (0°, 90°, 180°, 270°)
- Camera preview scaling and letterboxing
- Front camera horizontal mirroring
- Coordinate validation

## Key Concepts

### Coordinate Spaces

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Coordinate Spaces                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. NORMALIZED (0.0 - 1.0)     2. CAMERA PIXELS        3. CANVAS PIXELS │
│     (from detection)              (sensor resolution)     (screen)      │
│                                                                         │
│     ┌───────────┐              ┌───────────────┐       ┌─────────────┐  │
│     │ (0,0)     │              │ (0,0)         │       │ (0,0)       │  │
│     │     ●─────┤              │     ●─────────┤       │     ●───────┤  │
│     │     │     │   ────────▶  │     │         │  ───▶ │     │       │  │
│     │     │     │              │     │         │       │     │       │  │
│     └─────┴─────┘              └─────┴─────────┘       └─────┴───────┘  │
│           (1,1)                      (1920,1080)             (390,844)  │
│                                                                         │
│  Detection outputs        Camera sensor             Flutter canvas      │
│  normalized coords        dimensions vary           (device screen)     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Orientation Handling

Device orientation affects how camera frames map to screen:

```
Portrait (0°)           Landscape Left (90°)
┌───────────┐           ┌───────────────────┐
│ ┌───────┐ │           │ ┌───────────────┐ │
│ │       │ │           │ │               │ │
│ │ Camera│ │           │ │    Camera     │ │
│ │       │ │           │ │               │ │
│ └───────┘ │           │ └───────────────┘ │
└───────────┘           └───────────────────┘
```

When device rotates, coordinates must be transformed to maintain correct mapping.

### Aspect Ratio Fitting

Camera aspect ratio often differs from screen aspect ratio. Common strategies:

1. **Fill** (crop) — Camera fills screen, edges cropped
2. **Fit** (letterbox) — Entire camera visible, black bars added
3. **Cover** — Most common for camera apps, similar to fill

## Implementation

### Transformer Configuration

```dart
class CoordinateTransformConfig {
  final Size cameraResolution;
  final Size canvasSize;
  final int deviceOrientation; // 0, 90, 180, 270
  final bool isFrontCamera;
  final bool useFitMode; // true = letterbox, false = fill

  const CoordinateTransformConfig({
    required this.cameraResolution,
    required this.canvasSize,
    required this.deviceOrientation,
    this.isFrontCamera = false,
    this.useFitMode = false,
  });
}
```

### Coordinate Transformer

```dart
import 'dart:ui';

class QuadCoordinateTransformer {
  final CoordinateTransformConfig config;

  // Cached transform parameters
  late final double _scale;
  late final Offset _offset;
  late final Size _effectiveCameraSize;

  QuadCoordinateTransformer({required this.config}) {
    _calculateTransform();
  }

  void _calculateTransform() {
    // Account for orientation: swap dimensions if rotated 90° or 270°
    final rotated = config.deviceOrientation == 90 || 
                    config.deviceOrientation == 270;
    
    _effectiveCameraSize = rotated
        ? Size(config.cameraResolution.height, config.cameraResolution.width)
        : config.cameraResolution;

    // Calculate scale to fit/fill canvas
    final scaleX = config.canvasSize.width / _effectiveCameraSize.width;
    final scaleY = config.canvasSize.height / _effectiveCameraSize.height;

    if (config.useFitMode) {
      // Fit: use smaller scale, add letterboxing
      _scale = scaleX < scaleY ? scaleX : scaleY;
    } else {
      // Fill: use larger scale, crop edges
      _scale = scaleX > scaleY ? scaleX : scaleY;
    }

    // Calculate offset for centering
    final scaledWidth = _effectiveCameraSize.width * _scale;
    final scaledHeight = _effectiveCameraSize.height * _scale;
    _offset = Offset(
      (config.canvasSize.width - scaledWidth) / 2,
      (config.canvasSize.height - scaledHeight) / 2,
    );
  }

  /// Transform a single normalized point to canvas coordinates
  Offset transform(NormalizedPoint point) {
    double x = point.x;
    double y = point.y;

    // 1. Apply rotation based on device orientation
    switch (config.deviceOrientation) {
      case 90:
        final temp = x;
        x = 1.0 - y;
        y = temp;
        break;
      case 180:
        x = 1.0 - x;
        y = 1.0 - y;
        break;
      case 270:
        final temp = x;
        x = y;
        y = 1.0 - temp;
        break;
      case 0:
      default:
        // No rotation needed
        break;
    }

    // 2. Mirror horizontally for front camera
    if (config.isFrontCamera) {
      x = 1.0 - x;
    }

    // 3. Scale to canvas dimensions
    final scaledX = x * _effectiveCameraSize.width * _scale;
    final scaledY = y * _effectiveCameraSize.height * _scale;

    // 4. Apply centering offset
    return Offset(scaledX + _offset.dx, scaledY + _offset.dy);
  }

  /// Transform an entire quad
  List<Offset> transformQuad(DetectedQuad quad) {
    return quad.corners.map(transform).toList();
  }

  /// Inverse transform: canvas point to normalized point
  NormalizedPoint? inverseTransform(Offset canvasPoint) {
    // Remove offset
    double x = canvasPoint.dx - _offset.dx;
    double y = canvasPoint.dy - _offset.dy;

    // Check bounds
    final scaledWidth = _effectiveCameraSize.width * _scale;
    final scaledHeight = _effectiveCameraSize.height * _scale;
    if (x < 0 || x > scaledWidth || y < 0 || y > scaledHeight) {
      return null; // Outside camera area
    }

    // Unscale
    x = x / (_effectiveCameraSize.width * _scale);
    y = y / (_effectiveCameraSize.height * _scale);

    // Unmirror front camera
    if (config.isFrontCamera) {
      x = 1.0 - x;
    }

    // Unrotate
    switch (config.deviceOrientation) {
      case 90:
        final temp = y;
        y = 1.0 - x;
        x = temp;
        break;
      case 180:
        x = 1.0 - x;
        y = 1.0 - y;
        break;
      case 270:
        final temp = x;
        x = 1.0 - y;
        y = temp;
        break;
    }

    return NormalizedPoint(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
  }

  /// Get the visible camera area in canvas coordinates
  Rect get visibleCameraArea {
    return Rect.fromLTWH(
      _offset.dx,
      _offset.dy,
      _effectiveCameraSize.width * _scale,
      _effectiveCameraSize.height * _scale,
    );
  }
}
```

### Factory for Common Scenarios

```dart
class CoordinateTransformerFactory {
  /// Create transformer from camera controller and layout constraints
  static QuadCoordinateTransformer fromCameraController(
    CameraController controller,
    BoxConstraints constraints,
    int deviceOrientation,
  ) {
    final cameraSize = Size(
      controller.value.previewSize!.width,
      controller.value.previewSize!.height,
    );

    return QuadCoordinateTransformer(
      config: CoordinateTransformConfig(
        cameraResolution: cameraSize,
        canvasSize: Size(constraints.maxWidth, constraints.maxHeight),
        deviceOrientation: deviceOrientation,
        isFrontCamera: controller.description.lensDirection == 
                       CameraLensDirection.front,
      ),
    );
  }
}
```

### Widget Integration

```dart
/// Widget that provides coordinate transformer to children
class TransformProvider extends StatelessWidget {
  final CameraController controller;
  final Widget Function(QuadCoordinateTransformer transformer) builder;

  const TransformProvider({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get device orientation
        final orientation = MediaQuery.of(context).orientation;
        final deviceOrientation = _orientationToDegrees(orientation);

        final transformer = CoordinateTransformerFactory.fromCameraController(
          controller,
          constraints,
          deviceOrientation,
        );

        return builder(transformer);
      },
    );
  }

  int _orientationToDegrees(Orientation orientation) {
    // Simplified - in practice, use platform channels for exact sensor orientation
    return orientation == Orientation.portrait ? 0 : 90;
  }
}
```

## Validation

### Bounds Checking

```dart
extension TransformValidation on QuadCoordinateTransformer {
  /// Check if all corners are within canvas bounds
  bool isQuadVisible(DetectedQuad quad) {
    final canvasCorners = transformQuad(quad);
    return canvasCorners.every((corner) =>
        corner.dx >= 0 &&
        corner.dx <= config.canvasSize.width &&
        corner.dy >= 0 &&
        corner.dy <= config.canvasSize.height);
  }

  /// Check if quad is at least partially visible
  bool isQuadPartiallyVisible(DetectedQuad quad) {
    final canvasCorners = transformQuad(quad);
    return canvasCorners.any((corner) =>
        corner.dx >= 0 &&
        corner.dx <= config.canvasSize.width &&
        corner.dy >= 0 &&
        corner.dy <= config.canvasSize.height);
  }
}
```

## Unit Tests

```dart
void main() {
  group('QuadCoordinateTransformer', () {
    group('Basic transformation', () {
      test('transforms center point correctly', () {
        final transformer = QuadCoordinateTransformer(
          config: CoordinateTransformConfig(
            cameraResolution: Size(1920, 1080),
            canvasSize: Size(390, 844),
            deviceOrientation: 0,
          ),
        );

        final center = NormalizedPoint(0.5, 0.5);
        final transformed = transformer.transform(center);

        // Should be near canvas center
        expect(transformed.dx, closeTo(195, 50));
        expect(transformed.dy, closeTo(422, 50));
      });

      test('transforms corners correctly', () {
        final transformer = QuadCoordinateTransformer(
          config: CoordinateTransformConfig(
            cameraResolution: Size(100, 100),
            canvasSize: Size(100, 100),
            deviceOrientation: 0,
          ),
        );

        expect(transformer.transform(NormalizedPoint(0, 0)), 
               equals(Offset(0, 0)));
        expect(transformer.transform(NormalizedPoint(1, 1)), 
               equals(Offset(100, 100)));
      });
    });

    group('Orientation handling', () {
      test('90° rotation swaps and inverts x', () {
        final transformer = QuadCoordinateTransformer(
          config: CoordinateTransformConfig(
            cameraResolution: Size(100, 100),
            canvasSize: Size(100, 100),
            deviceOrientation: 90,
          ),
        );

        // (0.2, 0.3) at 90° → (1-0.3, 0.2) = (0.7, 0.2)
        final point = NormalizedPoint(0.2, 0.3);
        final transformed = transformer.transform(point);

        // Account for dimension swap in scaling
        expect(transformed.dx, closeTo(70, 1));
        expect(transformed.dy, closeTo(20, 1));
      });

      test('180° rotation inverts both axes', () {
        final transformer = QuadCoordinateTransformer(
          config: CoordinateTransformConfig(
            cameraResolution: Size(100, 100),
            canvasSize: Size(100, 100),
            deviceOrientation: 180,
          ),
        );

        final point = NormalizedPoint(0.2, 0.3);
        final transformed = transformer.transform(point);

        expect(transformed.dx, closeTo(80, 1));
        expect(transformed.dy, closeTo(70, 1));
      });
    });

    group('Front camera mirroring', () {
      test('mirrors horizontally', () {
        final transformer = QuadCoordinateTransformer(
          config: CoordinateTransformConfig(
            cameraResolution: Size(100, 100),
            canvasSize: Size(100, 100),
            deviceOrientation: 0,
            isFrontCamera: true,
          ),
        );

        final point = NormalizedPoint(0.2, 0.5);
        final transformed = transformer.transform(point);

        expect(transformed.dx, closeTo(80, 1)); // Mirrored
        expect(transformed.dy, closeTo(50, 1)); // Unchanged
      });
    });

    group('Aspect ratio handling', () {
      test('fill mode crops edges', () {
        final transformer = QuadCoordinateTransformer(
          config: CoordinateTransformConfig(
            cameraResolution: Size(1920, 1080), // 16:9
            canvasSize: Size(400, 800),          // 1:2 (taller)
            deviceOrientation: 0,
            useFitMode: false,
          ),
        );

        // In fill mode, some camera content is outside canvas
        final topLeft = transformer.transform(NormalizedPoint(0, 0));
        
        // X might be negative (cropped)
        expect(topLeft.dx, lessThan(0));
      });

      test('fit mode adds letterboxing', () {
        final transformer = QuadCoordinateTransformer(
          config: CoordinateTransformConfig(
            cameraResolution: Size(1920, 1080), // 16:9
            canvasSize: Size(400, 800),          // 1:2 (taller)
            deviceOrientation: 0,
            useFitMode: true,
          ),
        );

        // In fit mode, all camera content visible with offset
        final visibleArea = transformer.visibleCameraArea;
        
        // Should have vertical letterboxing (offset from top)
        expect(visibleArea.top, greaterThan(0));
      });
    });

    group('Inverse transformation', () {
      test('round-trips correctly', () {
        final transformer = QuadCoordinateTransformer(
          config: CoordinateTransformConfig(
            cameraResolution: Size(1920, 1080),
            canvasSize: Size(390, 844),
            deviceOrientation: 0,
          ),
        );

        final original = NormalizedPoint(0.3, 0.7);
        final transformed = transformer.transform(original);
        final recovered = transformer.inverseTransform(transformed);

        expect(recovered, isNotNull);
        expect(recovered!.x, closeTo(original.x, 0.01));
        expect(recovered.y, closeTo(original.y, 0.01));
      });

      test('returns null for points outside camera area', () {
        final transformer = QuadCoordinateTransformer(
          config: CoordinateTransformConfig(
            cameraResolution: Size(100, 100),
            canvasSize: Size(100, 100),
            deviceOrientation: 0,
          ),
        );

        final outside = Offset(-10, 50);
        expect(transformer.inverseTransform(outside), isNull);
      });
    });

    group('Quad transformation', () {
      test('preserves corner order', () {
        final transformer = QuadCoordinateTransformer(
          config: CoordinateTransformConfig(
            cameraResolution: Size(100, 100),
            canvasSize: Size(100, 100),
            deviceOrientation: 0,
          ),
        );

        final quad = DetectedQuad(
          topLeft: NormalizedPoint(0.2, 0.2),
          topRight: NormalizedPoint(0.8, 0.2),
          bottomRight: NormalizedPoint(0.8, 0.8),
          bottomLeft: NormalizedPoint(0.2, 0.8),
        );

        final corners = transformer.transformQuad(quad);

        // Verify order: TL, TR, BR, BL
        expect(corners[0].dx, lessThan(corners[1].dx)); // TL.x < TR.x
        expect(corners[1].dy, lessThan(corners[2].dy)); // TR.y < BR.y
        expect(corners[2].dx, greaterThan(corners[3].dx)); // BR.x > BL.x
      });
    });
  });
}
```

## Platform-Specific Considerations

### iOS
- Camera orientation is relative to device's natural orientation
- Use `CameraController.value.deviceOrientation` for current orientation
- Front camera preview is already mirrored by system

### Android
- Sensor orientation varies by device
- May need to query `CameraSelectorCameraInfo.sensorRotationDegrees`
- Front camera mirroring behavior varies

### Getting Accurate Orientation

```dart
/// Platform-specific orientation detection
int getAccurateDeviceOrientation(CameraController controller) {
  // This is simplified - production code should use platform channels
  // to get actual sensor orientation
  
  final sensorOrientation = controller.description.sensorOrientation;
  final deviceOrientation = controller.value.deviceOrientation;
  
  // Calculate relative orientation
  // (This varies by platform and requires careful testing)
  
  return sensorOrientation; // Simplified
}
```

## Common Pitfalls

1. **Ignoring orientation** — Coordinates will be wrong by 90°/180°/270°

2. **Wrong dimension order** — Camera reports size as (width, height) but may be rotated

3. **Forgetting front camera mirror** — Preview will appear flipped

4. **Assuming aspect ratios match** — Always calculate proper scaling

5. **Integer truncation** — Use doubles throughout, round only for final pixels

## Dependencies

- `geometry-validation.md` (for `DetectedQuad`, `NormalizedPoint`)

## Related Skills

- `overlay-rendering.md` — Uses transformed coordinates for drawing
- `capture-pipeline.md` — Needs inverse transform for user corner adjustments
