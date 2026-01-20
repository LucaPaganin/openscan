# Epic 4: Edge Detection

## Epic Overview

**Goal**: Implement real-time document boundary detection that identifies the four corners of a document in the camera preview. This epic adds the "smart" to the scanner — automatically finding where the document is in the frame.

**Duration**: 2 Sprints (2 weeks)

**Epic Owner**: Luca (Scrum Master)

**Phase**: 1 (Flutter MVP — No Backend Required)

**Dependencies**: E2 (Camera Module) must be complete

---

## Success Criteria

By the end of this epic:
- [ ] Real-time edge detection overlay displays on camera preview
- [ ] Four corners of document are detected and highlighted
- [ ] Detection works at minimum 15fps on mid-range devices
- [ ] Visual feedback shows when document is properly detected
- [ ] Detection handles various document types (white paper, receipts, cards)
- [ ] Detection works in various lighting conditions (with reasonable limits)
- [ ] All tests pass with success and failure scenarios

---

## User Stories

### US-4.1: Edge Detection Service

**As a** developer  
**I want** an edge detection algorithm  
**So that** I can find document boundaries in camera frames

**Acceptance Criteria**:
- Service accepts image bytes and returns detected corners (or null if none found)
- Detection uses contour-based approach (Canny edge + contour finding)
- Returns four points representing document corners in clockwise order
- Processing completes within 50ms per frame on average
- Handles both landscape and portrait orientations

**Dependencies**:
```yaml
dependencies:
  opencv_dart: ^1.0.0  # OpenCV bindings for Dart
```

**Note**: If `opencv_dart` proves problematic, fallback options:
- `edge_detection: ^1.1.2` (simpler, less control)
- Custom implementation using `image` package (slower but pure Dart)

**Implementation**:
```dart
// lib/features/camera/domain/services/edge_detection_service.dart

import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class EdgeDetectionService {
  /// Detects document edges in the given image bytes.
  /// Returns four corners in clockwise order starting from top-left,
  /// or null if no document detected.
  Future<DetectedDocument?> detectEdges(Uint8List imageBytes) async {
    try {
      // Decode image
      final mat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
      if (mat.isEmpty) return null;
      
      // Convert to grayscale
      final gray = cv.cvtColor(mat, cv.COLOR_BGR2GRAY);
      
      // Apply Gaussian blur to reduce noise
      final blurred = cv.gaussianBlur(gray, (5, 5), 0);
      
      // Edge detection using Canny
      final edges = cv.canny(blurred, 75, 200);
      
      // Find contours
      final (contours, _) = cv.findContours(
        edges,
        cv.RETR_LIST,
        cv.CHAIN_APPROX_SIMPLE,
      );
      
      // Find the largest quadrilateral contour
      final quad = _findLargestQuadrilateral(contours, mat.width, mat.height);
      
      // Cleanup
      mat.dispose();
      gray.dispose();
      blurred.dispose();
      edges.dispose();
      
      return quad;
    } catch (e) {
      throw EdgeDetectionException('Failed to detect edges: $e');
    }
  }
  
  DetectedDocument? _findLargestQuadrilateral(
    List<cv.VecPoint> contours,
    int imageWidth,
    int imageHeight,
  ) {
    final imageArea = imageWidth * imageHeight;
    final minArea = imageArea * 0.1; // Document must be at least 10% of frame
    final maxArea = imageArea * 0.95; // Document can't be larger than 95%
    
    DetectedDocument? bestDocument;
    double bestArea = 0;
    
    for (final contour in contours) {
      final area = cv.contourArea(contour);
      
      // Skip if too small or too large
      if (area < minArea || area > maxArea) continue;
      
      // Approximate contour to polygon
      final peri = cv.arcLength(contour, true);
      final approx = cv.approxPolyDP(contour, 0.02 * peri, true);
      
      // We want exactly 4 corners (quadrilateral)
      if (approx.length == 4 && area > bestArea) {
        // Verify it's convex
        if (cv.isContourConvex(approx)) {
          bestArea = area;
          bestDocument = DetectedDocument(
            corners: _orderCorners(approx, imageWidth, imageHeight),
            confidence: _calculateConfidence(area, imageArea),
            imageSize: Size(imageWidth.toDouble(), imageHeight.toDouble()),
          );
        }
      }
    }
    
    return bestDocument;
  }
  
  /// Orders corners: top-left, top-right, bottom-right, bottom-left
  List<Point> _orderCorners(cv.VecPoint approx, int width, int height) {
    final points = approx.toList().map((p) => Point(p.x.toDouble(), p.y.toDouble())).toList();
    
    // Sort by sum of coordinates (top-left has smallest sum)
    points.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
    final topLeft = points[0];
    final bottomRight = points[3];
    
    // Sort by difference (top-right has largest difference)
    points.sort((a, b) => (b.x - b.y).compareTo(a.x - a.y));
    final topRight = points[0];
    final bottomLeft = points[3];
    
    return [topLeft, topRight, bottomRight, bottomLeft];
  }
  
  double _calculateConfidence(double contourArea, int imageArea) {
    // Confidence based on how well-defined the contour is
    // Larger documents relative to frame = higher confidence
    final ratio = contourArea / imageArea;
    return (ratio * 2).clamp(0.0, 1.0);
  }
}

// lib/features/camera/domain/models/detected_document.dart

class DetectedDocument {
  final List<Point> corners; // 4 corners: TL, TR, BR, BL
  final double confidence;   // 0.0 to 1.0
  final Size imageSize;      // Size of source image
  
  const DetectedDocument({
    required this.corners,
    required this.confidence,
    required this.imageSize,
  });
  
  bool get isHighConfidence => confidence > 0.6;
  
  /// Converts corners to normalized coordinates (0.0 to 1.0)
  List<Point> get normalizedCorners {
    return corners.map((c) => Point(
      c.x / imageSize.width,
      c.y / imageSize.height,
    )).toList();
  }
}

class Point {
  final double x;
  final double y;
  
  const Point(this.x, this.y);
}

// lib/core/errors/edge_detection_exceptions.dart

class EdgeDetectionException implements Exception {
  final String message;
  EdgeDetectionException(this.message);
}
```

**Tests Required**:
- ✅ `detectEdges()` returns DetectedDocument with 4 corners for valid document image
- ✅ `detectEdges()` returns null for image with no clear document

---

### US-4.2: Camera Frame Stream

**As a** developer  
**I want** to process camera frames in real-time  
**So that** edge detection can run continuously

**Acceptance Criteria**:
- Camera streams frames at configurable interval (default: every 100ms)
- Frame processing runs on background isolate to avoid UI jank
- Frames are skipped if previous detection is still running
- Memory is managed properly (no frame accumulation)

**Implementation**:
```dart
// lib/features/camera/domain/services/frame_processor.dart

import 'dart:async';
import 'dart:isolate';
import 'package:camera/camera.dart';

class FrameProcessor {
  final EdgeDetectionService _edgeService;
  final Duration _frameInterval;
  
  Timer? _frameTimer;
  bool _isProcessing = false;
  StreamController<DetectedDocument?>? _resultController;
  
  FrameProcessor({
    required EdgeDetectionService edgeService,
    Duration frameInterval = const Duration(milliseconds: 100),
  }) : _edgeService = edgeService,
       _frameInterval = frameInterval;
  
  Stream<DetectedDocument?> get detectionStream {
    _resultController ??= StreamController<DetectedDocument?>.broadcast();
    return _resultController!.stream;
  }
  
  void startProcessing(CameraController controller) {
    stopProcessing();
    
    _frameTimer = Timer.periodic(_frameInterval, (_) async {
      if (_isProcessing) return; // Skip if still processing previous frame
      
      try {
        _isProcessing = true;
        final image = await controller.takePicture();
        final bytes = await image.readAsBytes();
        
        final result = await _edgeService.detectEdges(bytes);
        _resultController?.add(result);
        
        // Clean up temp file
        await image.delete();
      } catch (e) {
        // Log but don't crash on frame processing errors
        debugPrint('Frame processing error: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }
  
  void stopProcessing() {
    _frameTimer?.cancel();
    _frameTimer = null;
    _isProcessing = false;
  }
  
  void dispose() {
    stopProcessing();
    _resultController?.close();
    _resultController = null;
  }
}
```

**Alternative using CameraImage stream** (more efficient):
```dart
// If camera package supports image streaming, use this instead

void startProcessingStream(CameraController controller) {
  controller.startImageStream((CameraImage image) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    try {
      final bytes = _convertCameraImage(image);
      final result = await _edgeService.detectEdges(bytes);
      _resultController?.add(result);
    } finally {
      _isProcessing = false;
    }
  });
}

Uint8List _convertCameraImage(CameraImage image) {
  // Convert YUV420 or BGRA to RGB bytes
  // Implementation depends on platform
}
```

**Tests Required**:
- ✅ Frame processor emits detection results on stream
- ✅ Frame processor skips frames when processing is slow

---

### US-4.3: Detection Overlay Widget

**As a** user  
**I want** to see where the app detected my document  
**So that** I know if it's positioned correctly

**Acceptance Criteria**:
- Semi-transparent overlay draws on top of camera preview
- Four corners are connected by lines forming a quadrilateral
- Corners are highlighted with circular handles
- Overlay color indicates detection quality:
  - Green: high confidence (ready to capture)
  - Yellow: medium confidence (detected but not ideal)
  - No overlay: no document detected
- Overlay updates smoothly (no flickering)

**UI Specifications**:
```
┌─────────────────────────────────────────┐
│                                         │
│      ●─────────────────────●            │
│      │                     │            │
│      │    [Document]       │            │
│      │                     │            │
│      │                     │            │
│      ●─────────────────────●            │
│                                         │
└─────────────────────────────────────────┘

Line: 3dp stroke, semi-transparent
Corner handles: 12dp diameter circles
Green: #4CAF50 (high confidence)
Yellow: #FFC107 (medium confidence)
```

**Implementation**:
```dart
// lib/features/camera/presentation/widgets/detection_overlay.dart

class DetectionOverlay extends StatelessWidget {
  final DetectedDocument? detection;
  final Size previewSize;
  
  const DetectionOverlay({
    super.key,
    this.detection,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    if (detection == null) {
      return const SizedBox.shrink();
    }
    
    return CustomPaint(
      size: previewSize,
      painter: _DetectionPainter(
        corners: detection!.normalizedCorners,
        confidence: detection!.confidence,
      ),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<Point> corners;
  final double confidence;
  
  _DetectionPainter({
    required this.corners,
    required this.confidence,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;
    
    final color = confidence > 0.6 
        ? const Color(0xFF4CAF50)  // Green
        : const Color(0xFFFFC107); // Yellow
    
    final linePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final handlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Convert normalized coordinates to actual pixels
    final points = corners.map((c) => Offset(
      c.x * size.width,
      c.y * size.height,
    )).toList();
    
    // Draw filled area
    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();
    
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, linePaint);
    
    // Draw corner handles
    for (final point in points) {
      canvas.drawCircle(point, 12, handlePaint);
      canvas.drawCircle(point, 10, Paint()..color = Colors.white);
    }
  }
  
  @override
  bool shouldRepaint(_DetectionPainter oldDelegate) {
    return corners != oldDelegate.corners || 
           confidence != oldDelegate.confidence;
  }
}
```

**Tests Required**:
- ✅ Overlay renders green when confidence > 0.6
- ✅ Overlay renders nothing when detection is null

---

### US-4.4: Detection State Provider

**As a** developer  
**I want** detection state managed via Riverpod  
**So that** the UI reacts to detection changes

**Acceptance Criteria**:
- Provider holds current detection result
- Provider manages frame processor lifecycle
- Detection updates trigger UI rebuild
- Provider cleans up resources on dispose

**Implementation**:
```dart
// lib/features/camera/presentation/providers/edge_detection_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edge_detection_provider.g.dart';

@riverpod
EdgeDetectionService edgeDetectionService(EdgeDetectionServiceRef ref) {
  return EdgeDetectionService();
}

@riverpod
class DetectionNotifier extends _$DetectionNotifier {
  FrameProcessor? _frameProcessor;
  StreamSubscription<DetectedDocument?>? _subscription;
  
  @override
  DetectedDocument? build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _frameProcessor?.dispose();
    });
    return null;
  }
  
  void startDetection(CameraController controller) {
    final edgeService = ref.read(edgeDetectionServiceProvider);
    
    _frameProcessor = FrameProcessor(edgeService: edgeService);
    _subscription = _frameProcessor!.detectionStream.listen((result) {
      state = result;
    });
    
    _frameProcessor!.startProcessing(controller);
  }
  
  void stopDetection() {
    _subscription?.cancel();
    _frameProcessor?.stopProcessing();
    state = null;
  }
  
  void pauseDetection() {
    _frameProcessor?.stopProcessing();
  }
  
  void resumeDetection(CameraController controller) {
    _frameProcessor?.startProcessing(controller);
  }
}
```

**Tests Required**:
- ✅ Provider starts detection and emits results
- ✅ Provider cleans up resources on dispose

---

### US-4.5: Integrate Detection with Camera Screen

**As a** user  
**I want** edge detection running while I use the camera  
**So that** I get real-time feedback on document positioning

**Acceptance Criteria**:
- Detection starts automatically when camera initializes
- Detection pauses when app goes to background
- Detection resumes when app returns to foreground
- Detection overlay displays on top of camera preview
- Capture button shows different state based on detection confidence

**Implementation**:
```dart
// lib/features/camera/presentation/screens/camera_screen.dart (updated)

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = ref.read(cameraProvider).valueOrNull;
    if (cameraController == null) return;
    
    if (state == AppLifecycleState.inactive) {
      ref.read(detectionNotifierProvider.notifier).pauseDetection();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(detectionNotifierProvider.notifier).resumeDetection(cameraController);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraAsync = ref.watch(cameraProvider);
    final detection = ref.watch(detectionNotifierProvider);
    
    return Scaffold(
      body: cameraAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Camera error: $e')),
        data: (controller) {
          if (controller == null) {
            return const Center(child: Text('No camera available'));
          }
          
          // Start detection when camera is ready
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(detectionNotifierProvider.notifier).startDetection(controller);
          });
          
          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview
              CameraPreview(controller: controller),
              
              // Detection overlay
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return DetectionOverlay(
                      detection: detection,
                      previewSize: Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                    );
                  },
                ),
              ),
              
              // Controls bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CameraControlsBar(
                  onCapture: () => _onCapture(controller),
                  onFlashToggle: () => ref.read(flashModeNotifierProvider.notifier).cycle(),
                  onCameraFlip: () => ref.read(cameraProvider.notifier).flipCamera(),
                  flashMode: ref.watch(flashModeNotifierProvider),
                  isDocumentDetected: detection?.isHighConfidence ?? false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _onCapture(CameraController controller) async {
    // Capture logic from E2
  }
}
```

**Updated Capture Button** (shows ready state):
```dart
// lib/features/camera/presentation/widgets/capture_button.dart (updated)

class CaptureButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isCapturing;
  final bool isDocumentDetected;

  const CaptureButton({
    super.key,
    required this.onPressed,
    this.isCapturing = false,
    this.isDocumentDetected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDocumentDetected 
        ? const Color(0xFF4CAF50)  // Green when ready
        : Colors.white;
    
    return GestureDetector(
      onTap: isCapturing ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isCapturing ? 30 : 60,
            height: isCapturing ? 30 : 60,
            decoration: BoxDecoration(
              shape: isCapturing ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isCapturing ? BorderRadius.circular(4) : null,
              border: Border.all(
                color: isDocumentDetected ? Colors.white : Colors.black12,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Tests Required**:
- ✅ Camera screen displays detection overlay when document detected
- ✅ Camera screen hides overlay when no document detected

---

### US-4.6: Detection Feedback Indicator

**As a** user  
**I want** clear feedback when the app is ready to capture  
**So that** I know when to take the photo

**Acceptance Criteria**:
- Status indicator shows current detection state
- States: "Position document", "Hold steady", "Ready!"
- Indicator animates smoothly between states
- Optional: haptic feedback when entering "Ready" state

**Implementation**:
```dart
// lib/features/camera/presentation/widgets/detection_status_indicator.dart

class DetectionStatusIndicator extends StatelessWidget {
  final DetectedDocument? detection;
  
  const DetectionStatusIndicator({super.key, this.detection});

  @override
  Widget build(BuildContext context) {
    final status = _getStatus();
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(status.text),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: status.color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              status.text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  _DetectionStatus _getStatus() {
    if (detection == null) {
      return _DetectionStatus(
        text: 'Position document',
        icon: Icons.crop_free,
        color: Colors.grey,
      );
    }
    
    if (detection!.isHighConfidence) {
      return _DetectionStatus(
        text: 'Ready!',
        icon: Icons.check_circle,
        color: const Color(0xFF4CAF50),
      );
    }
    
    return _DetectionStatus(
      text: 'Hold steady',
      icon: Icons.center_focus_strong,
      color: const Color(0xFFFFC107),
    );
  }
}

class _DetectionStatus {
  final String text;
  final IconData icon;
  final Color color;
  
  const _DetectionStatus({
    required this.text,
    required this.icon,
    required this.color,
  });
}
```

**Position in Camera Screen**:
```dart
// Add to camera screen stack
Positioned(
  top: MediaQuery.of(context).padding.top + 16,
  left: 0,
  right: 0,
  child: Center(
    child: DetectionStatusIndicator(detection: detection),
  ),
),
```

**Tests Required**:
- ✅ Indicator shows "Ready!" for high confidence detection
- ✅ Indicator shows "Position document" when detection is null

---

## Technical Specifications

### Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| Detection latency | < 50ms | Per frame processing |
| Frame rate | 10-15 fps | Detection updates |
| CPU usage | < 30% | Background processing |
| Memory | < 50MB | Image buffers |

### OpenCV Pipeline

```
Input Frame
     │
     ▼
┌─────────────────┐
│ Convert to Gray │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Gaussian Blur   │ (5x5 kernel)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Canny Edge      │ (threshold: 75-200)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Find Contours   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Filter & Approx │ → Quadrilateral only
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Order Corners   │ → TL, TR, BR, BL
└────────┬────────┘
         │
         ▼
DetectedDocument
```

### Corner Ordering Algorithm

Corners are ordered consistently for perspective correction (E6):

```
  TL ●─────────● TR
     │         │
     │         │
     │         │
  BL ●─────────● BR

1. Sum (x + y): smallest = TL, largest = BR
2. Diff (x - y): largest = TR, smallest = BL
```

---

## Definition of Done

- [ ] Edge detection service processes images and returns corners
- [ ] Frame processor streams detection results
- [ ] Detection overlay renders on camera preview
- [ ] Corner ordering is consistent (TL, TR, BR, BL)
- [ ] Status indicator shows detection state
- [ ] Capture button indicates ready state
- [ ] Detection pauses/resumes with app lifecycle
- [ ] Performance meets targets (< 50ms latency)
- [ ] All tests pass (minimum 2 scenarios per component)
- [ ] No lint warnings

---

## Out of Scope

The following are explicitly NOT part of this epic:
- Manual corner adjustment (Epic 5)
- Perspective correction (Epic 6)
- Auto-capture trigger (Epic 9)
- Curve detection for books (Phase 2)

---

## Implementation Order

Suggested order for Claude Code:

1. Add `opencv_dart` dependency to `pubspec.yaml`
2. Create DetectedDocument model
3. Create Point class (if not using dart:ui Offset)
4. Create edge detection exception class
5. Implement EdgeDetectionService with corner detection
6. Implement corner ordering algorithm
7. Create FrameProcessor for real-time streaming
8. Create DetectionNotifier provider
9. Create DetectionOverlay widget with CustomPainter
10. Create DetectionStatusIndicator widget
11. Update CaptureButton to show ready state
12. Integrate detection into CameraScreen
13. Handle app lifecycle (pause/resume detection)
14. Write tests for all components
15. Performance test on real device
16. Run `flutter analyze` and fix issues

---

## Notes for Claude Code

When implementing this epic:

1. **Test on real device** — OpenCV performance varies significantly on simulators
2. **Handle OpenCV initialization** — May need async init on first use
3. **Memory management** — Dispose Mat objects after use to prevent leaks
4. **Frame skipping** — Essential for performance; don't queue frames
5. **Fallback plan** — If `opencv_dart` has issues, document the problem and suggest alternatives
6. **Run build_runner** after creating providers

---

## Fallback: Pure Dart Implementation

If OpenCV bindings prove problematic, here's a simplified pure-Dart approach using the `image` package:

```dart
// Simplified edge detection without OpenCV
// Less accurate but more portable

Future<DetectedDocument?> detectEdgesSimple(Uint8List bytes) async {
  final image = img.decodeImage(bytes);
  if (image == null) return null;
  
  // Convert to grayscale
  final gray = img.grayscale(image);
  
  // Simple edge detection using Sobel-like filter
  final edges = img.sobel(gray);
  
  // Find document rectangle using simple heuristics
  // ... (simplified algorithm)
}
```

This is a backup only if OpenCV doesn't work. Prefer OpenCV for accuracy.

---

## Confirmed Decisions

- **Detection library**: opencv_dart (primary), edge_detection or pure Dart (fallback)
- **Frame interval**: 100ms (10fps detection rate)
- **Minimum document size**: 10% of frame
- **Confidence threshold**: 0.6 for "high confidence"
- **Corner order**: Clockwise from top-left (TL, TR, BR, BL)