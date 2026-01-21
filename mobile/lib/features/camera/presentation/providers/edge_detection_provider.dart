import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/detected_document.dart';
import '../../domain/services/edge_detection_service.dart';
import '../../domain/services/frame_processor.dart';

part 'edge_detection_provider.g.dart';

@riverpod
EdgeDetectionService edgeDetectionService(Ref ref) {
  return EdgeDetectionService();
}

@riverpod
class DetectionNotifier extends _$DetectionNotifier {
  FrameProcessor? _frameProcessor;
  StreamSubscription<DetectedDocument?>? _subscription;
  CameraController? _controller;
  bool _isDetecting = false;

  @override
  DetectedDocument? build() {
    ref.onDispose(() {
      _stopImageStream();
      _subscription?.cancel();
      _frameProcessor?.dispose();
    });
    return null;
  }

  void startDetection(CameraController controller) {
    // Avoid starting detection multiple times
    if (_isDetecting && _controller == controller) return;

    _stopImageStream();
    _subscription?.cancel();
    _frameProcessor?.dispose();

    _controller = controller;
    _isDetecting = true;

    final edgeService = ref.read(edgeDetectionServiceProvider);

    _frameProcessor = FrameProcessor(edgeService: edgeService);
    _subscription = _frameProcessor!.detectionStream.listen((result) {
      state = result;
    });

    _frameProcessor!.startProcessing(controller);
  }

  void stopDetection() {
    _stopImageStream();
    _subscription?.cancel();
    _frameProcessor?.stopProcessing();
    _isDetecting = false;
    state = null;
  }

  void pauseDetection() {
    _stopImageStream();
    _frameProcessor?.stopProcessing();
    _isDetecting = false;
  }

  void resumeDetection(CameraController controller) {
    if (_isDetecting) return;

    _controller = controller;
    _isDetecting = true;
    _frameProcessor?.startProcessing(controller);
  }

  void _stopImageStream() {
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        _controller!.stopImageStream();
      } catch (e) {
        debugPrint('Failed to stop image stream: $e');
      }
    }
  }
}
