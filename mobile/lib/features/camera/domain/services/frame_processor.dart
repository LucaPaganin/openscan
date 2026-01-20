import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../models/detected_document.dart';
import 'edge_detection_service.dart';

/// Processes camera frames for edge detection in real-time.
class FrameProcessor {
  FrameProcessor({
    required EdgeDetectionService edgeService,
    Duration frameInterval = const Duration(milliseconds: 100),
  })  : _edgeService = edgeService,
        _frameInterval = frameInterval;

  final EdgeDetectionService _edgeService;
  final Duration _frameInterval;

  Timer? _frameTimer;
  bool _isProcessing = false;
  StreamController<DetectedDocument?>? _resultController;

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

        // Note: XFile cleanup is handled automatically by the system
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
