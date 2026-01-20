import 'dart:async';

import 'package:camera/camera.dart';
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
