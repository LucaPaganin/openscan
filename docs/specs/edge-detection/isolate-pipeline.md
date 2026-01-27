# Isolate Pipeline Skill

## Purpose

Implement frame sampling and isolate communication for offloading CV processing from the UI thread. This ensures the camera preview stays smooth at 60fps while detection runs at 8-10fps in a background isolate.

## Scope

- Frame sampling/throttling from camera stream
- Y-plane extraction from YUV camera frames
- Isolate spawn and lifecycle management
- Bidirectional communication via SendPort/ReceivePort
- Memory-safe frame data transfer

## Key Concepts

### Why Isolates?

Flutter's UI runs on a single thread. OpenCV operations (blur, Canny, contours) are CPU-intensive and would cause frame drops if run on the UI thread. Isolates provide true parallelism with separate memory heaps.

### The Challenge: Data Transfer

Isolates don't share memory. Camera frames must be copied to the isolate, which has overhead. We minimize this by:
1. Extracting only the Y-plane (grayscale) — ~1/3 the data of full YUV
2. Sampling frames at 8fps, not 30fps
3. Using `TransferableTypedData` for zero-copy transfer when possible

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                          UI Thread                              │
│                                                                 │
│  CameraController ──→ onImageAvailable ──→ FrameProcessor       │
│       (30fps)              callback           (throttles)       │
│                                                    │            │
│                                                    ▼            │
│                                              [Send to isolate]  │
│                                                    │            │
│                              ┌─────────────────────┘            │
│                              │                                  │
│   resultStream ◀──────── ReceivePort                            │
│        │                                                        │
│        ▼                                                        │
│   QuadStateProvider ──→ QuadOverlayWidget                       │
└─────────────────────────────────────────────────────────────────┘
                               │
                    FrameData  │  FilteredQuadResult
                   (via copy)  ▼  (via copy)
┌─────────────────────────────────────────────────────────────────┐
│                      Detection Isolate                          │
│                                                                 │
│   ReceivePort ──→ PreviewPipeline ──→ SendPort (to main)        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Implementation

### Frame Data Structure

```dart
/// Data sent to the detection isolate
/// Must be serializable (no closures, no complex objects)
class FrameData {
  final Uint8List yPlane;
  final int width;
  final int height;
  final int timestamp;
  final int deviceOrientation; // 0, 90, 180, 270

  const FrameData({
    required this.yPlane,
    required this.width,
    required this.height,
    required this.timestamp,
    required this.deviceOrientation,
  });
}

/// Result from the detection isolate
class DetectionResult {
  final DetectedQuad? quad;
  final double confidence;
  final bool isLocked;
  final int stableFrameCount;
  final int frameTimestamp;
  final double processingTimeMs;

  const DetectionResult({
    this.quad,
    required this.confidence,
    required this.isLocked,
    required this.stableFrameCount,
    required this.frameTimestamp,
    required this.processingTimeMs,
  });
}
```

### Isolate Initialization Data

```dart
/// Data passed to isolate on spawn
/// Must be serializable
class _IsolateInitData {
  final SendPort sendPort;
  final int targetProcessingWidth;
  final double cannyLow;
  final double cannyHigh;
  final double minAreaRatio;
  final double maxAreaRatio;
  final double smoothingAlpha;
  final double deadZoneThreshold;
  final int lockFrameCount;

  const _IsolateInitData({
    required this.sendPort,
    required this.targetProcessingWidth,
    required this.cannyLow,
    required this.cannyHigh,
    required this.minAreaRatio,
    required this.maxAreaRatio,
    required this.smoothingAlpha,
    required this.deadZoneThreshold,
    required this.lockFrameCount,
  });
}
```

### Frame Processor (Main Thread)

```dart
import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';

/// Manages frame sampling and isolate communication
class FrameProcessor {
  final EdgeDetectionConfig config;

  Isolate? _isolate;
  SendPort? _isolateSendPort;
  ReceivePort? _mainReceivePort;

  DateTime _lastFrameTime = DateTime(0);
  bool _isProcessing = false;

  final _resultController = StreamController<DetectionResult>.broadcast();
  Stream<DetectionResult> get results => _resultController.stream;

  FrameProcessor({required this.config});

  /// Initialize the detection isolate
  Future<void> initialize() async {
    _mainReceivePort = ReceivePort();

    // Spawn isolate with init data
    _isolate = await Isolate.spawn(
      _detectionIsolateEntry,
      _IsolateInitData(
        sendPort: _mainReceivePort!.sendPort,
        targetProcessingWidth: config.targetProcessingWidth,
        cannyLow: config.cannyLow,
        cannyHigh: config.cannyHigh,
        minAreaRatio: config.minAreaRatio,
        maxAreaRatio: config.maxAreaRatio,
        smoothingAlpha: config.smoothingAlpha,
        deadZoneThreshold: config.deadZoneThreshold,
        lockFrameCount: config.lockFrameCount,
      ),
    );

    // First message from isolate is its SendPort
    final subscription = _mainReceivePort!.listen((message) {
      if (message is SendPort) {
        _isolateSendPort = message;
      } else if (message is DetectionResult) {
        _isProcessing = false;
        _resultController.add(message);
      }
    });

    // Wait for isolate to send its port
    while (_isolateSendPort == null) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  /// Process a camera frame (call from onImageAvailable callback)
  void processFrame(CameraImage image, int deviceOrientation) {
    // Throttle: skip if within min interval
    final now = DateTime.now();
    final minInterval = Duration(milliseconds: (1000 / config.targetFps).round());
    if (now.difference(_lastFrameTime) < minInterval) {
      return;
    }

    // Skip if previous frame still processing (back-pressure)
    if (_isProcessing) {
      return;
    }

    _lastFrameTime = now;
    _isProcessing = true;

    // Extract Y-plane (grayscale) from YUV420 format
    final yPlane = image.planes[0];
    
    // Copy bytes - required for isolate transfer
    final frameData = FrameData(
      yPlane: Uint8List.fromList(yPlane.bytes),
      width: image.width,
      height: image.height,
      timestamp: now.millisecondsSinceEpoch,
      deviceOrientation: deviceOrientation,
    );

    _isolateSendPort?.send(frameData);
  }

  /// Clean up resources
  Future<void> dispose() async {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isolateSendPort = null;
    _mainReceivePort?.close();
    await _resultController.close();
  }
}
```

### Isolate Entry Point

```dart
/// Entry point for detection isolate
/// This function runs in a separate isolate
void _detectionIsolateEntry(_IsolateInitData initData) {
  // Create port to receive frames from main thread
  final receivePort = ReceivePort();
  
  // Send our port back to main thread
  initData.sendPort.send(receivePort.sendPort);

  // Create pipeline with config
  final pipeline = PreviewDetectionPipeline(
    targetProcessingWidth: initData.targetProcessingWidth,
    cannyLow: initData.cannyLow,
    cannyHigh: initData.cannyHigh,
    minAreaRatio: initData.minAreaRatio,
    maxAreaRatio: initData.maxAreaRatio,
    smoothingAlpha: initData.smoothingAlpha,
    deadZoneThreshold: initData.deadZoneThreshold,
    lockFrameCount: initData.lockFrameCount,
  );

  // Process incoming frames
  receivePort.listen((message) {
    if (message is FrameData) {
      final stopwatch = Stopwatch()..start();
      
      final result = pipeline.process(message);
      
      stopwatch.stop();
      
      // Send result back to main thread
      initData.sendPort.send(DetectionResult(
        quad: result.quad,
        confidence: result.confidence,
        isLocked: result.isLocked,
        stableFrameCount: result.stableFrameCount,
        frameTimestamp: message.timestamp,
        processingTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
      ));
    }
  });
}
```

### Camera Integration

```dart
/// Example of integrating FrameProcessor with camera
class ScannerController {
  late CameraController _cameraController;
  late FrameProcessor _frameProcessor;
  late StreamSubscription<DetectionResult> _resultSubscription;

  Future<void> initialize() async {
    // Initialize camera
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _cameraController.initialize();

    // Initialize frame processor
    _frameProcessor = FrameProcessor(config: EdgeDetectionConfig());
    await _frameProcessor.initialize();

    // Subscribe to results
    _resultSubscription = _frameProcessor.results.listen((result) {
      // Update UI state via Riverpod or other state management
      _onDetectionResult(result);
    });

    // Start processing frames
    await _cameraController.startImageStream((image) {
      final orientation = _getDeviceOrientation();
      _frameProcessor.processFrame(image, orientation);
    });
  }

  int _getDeviceOrientation() {
    // Platform-specific orientation detection
    // Returns 0, 90, 180, or 270
    return 0; // Simplified
  }

  void _onDetectionResult(DetectionResult result) {
    // Handle detection result
  }

  Future<void> dispose() async {
    await _resultSubscription.cancel();
    await _cameraController.stopImageStream();
    await _cameraController.dispose();
    await _frameProcessor.dispose();
  }
}
```

## Memory Optimization

### Reusing Buffers (Advanced)

For high-performance scenarios, consider reusing buffers:

```dart
class OptimizedFrameProcessor {
  // Preallocated buffer for Y-plane
  Uint8List? _frameBuffer;
  int _bufferSize = 0;

  void processFrame(CameraImage image, int deviceOrientation) {
    final yPlane = image.planes[0];
    final requiredSize = yPlane.bytes.length;

    // Reuse buffer if same size, otherwise reallocate
    if (_frameBuffer == null || _bufferSize != requiredSize) {
      _frameBuffer = Uint8List(requiredSize);
      _bufferSize = requiredSize;
    }

    // Copy into reusable buffer
    _frameBuffer!.setAll(0, yPlane.bytes);

    // Send copy to isolate (still need to copy for isolate)
    final frameData = FrameData(
      yPlane: Uint8List.fromList(_frameBuffer!),
      // ...
    );
  }
}
```

### TransferableTypedData (Dart 2.15+)

For truly zero-copy transfer:

```dart
void processFrameZeroCopy(CameraImage image, int deviceOrientation) {
  final yPlane = image.planes[0];
  
  // Wrap in TransferableTypedData for zero-copy transfer
  final transferable = TransferableTypedData.fromList([
    yPlane.bytes.buffer.asUint8List(),
  ]);

  _isolateSendPort?.send({
    'data': transferable,
    'width': image.width,
    'height': image.height,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'orientation': deviceOrientation,
  });
}

// In isolate:
receivePort.listen((message) {
  if (message is Map) {
    final transferable = message['data'] as TransferableTypedData;
    final bytes = transferable.materialize().asUint8List();
    // bytes is now usable without copy
  }
});
```

## Testing

### Unit Tests

```dart
void main() {
  group('FrameProcessor', () {
    test('throttles frames to target fps', () async {
      final processor = FrameProcessor(
        config: EdgeDetectionConfig(targetFps: 10), // 100ms interval
      );
      await processor.initialize();

      var processedCount = 0;
      processor.results.listen((_) => processedCount++);

      // Simulate 30 frames in 1 second
      for (int i = 0; i < 30; i++) {
        processor.processFrame(mockCameraImage(), 0);
        await Future.delayed(Duration(milliseconds: 33));
      }

      // Should process ~10 frames, not 30
      expect(processedCount, lessThanOrEqualTo(12));
      expect(processedCount, greaterThanOrEqualTo(8));

      await processor.dispose();
    });

    test('applies back-pressure when isolate is busy', () async {
      // Create slow pipeline for testing
      final processor = FrameProcessor(
        config: EdgeDetectionConfig(),
      );
      await processor.initialize();

      // Send many frames rapidly
      for (int i = 0; i < 100; i++) {
        processor.processFrame(mockCameraImage(), 0);
      }

      // Should not queue unboundedly
      // (Implementation detail: _isProcessing flag)
      await processor.dispose();
    });

    test('cleans up isolate on dispose', () async {
      final processor = FrameProcessor(config: EdgeDetectionConfig());
      await processor.initialize();
      await processor.dispose();

      // Verify no memory leaks (manual inspection or memory profiling)
    });
  });
}

CameraImage mockCameraImage() {
  // Create mock camera image for testing
  // ...
}
```

### Integration Tests

```dart
testWidgets('camera stream processes without UI jank', (tester) async {
  // This test requires a real device or emulator with camera

  await tester.pumpWidget(MaterialApp(
    home: ScannerScreen(),
  ));

  // Let camera stream run for 5 seconds
  await tester.pump(Duration(seconds: 5));

  // Check for frame drops (requires instrumentation)
  // UI should maintain 60fps
});
```

## Common Pitfalls

1. **Forgetting to copy bytes** — `yPlane.bytes` is a view, not a copy. Isolates need owned data.

2. **Memory leaks on dispose** — Always kill the isolate and close ports.

3. **Race conditions** — Use `_isProcessing` flag to prevent queue buildup.

4. **Orientation handling** — Camera orientation varies by device; pass it explicitly.

5. **YUV format assumptions** — Not all devices use YUV420. Check `imageFormatGroup`.

## Dependencies

- `camera` plugin (or `camera_x`)
- `geometry-validation.md` (for `DetectedQuad` type)

## Related Skills

- `contour-detection.md` — Pipeline that runs inside the isolate
- `temporal-filtering.md` — Smoothing applied in the isolate
