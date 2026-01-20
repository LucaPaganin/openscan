import 'package:camera/camera.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/camera_exceptions.dart';
import '../../domain/models/captured_image.dart';

part 'camera_controller_provider.g.dart';

/// State for camera initialization and capture operations.
class CameraState {
  const CameraState({
    this.controller,
    this.isInitialized = false,
    this.isCapturing = false,
    this.error,
    this.cameras = const [],
    this.currentCameraIndex = 0,
  });

  final CameraController? controller;
  final bool isInitialized;
  final bool isCapturing;
  final Object? error;
  final List<CameraDescription> cameras;
  final int currentCameraIndex;

  CameraDescription? get currentCamera =>
      cameras.isNotEmpty ? cameras[currentCameraIndex] : null;

  bool get canFlip => cameras.length > 1;

  CameraState copyWith({
    CameraController? controller,
    bool? isInitialized,
    bool? isCapturing,
    Object? error,
    List<CameraDescription>? cameras,
    int? currentCameraIndex,
    bool clearError = false,
  }) {
    return CameraState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      isCapturing: isCapturing ?? this.isCapturing,
      error: clearError ? null : (error ?? this.error),
      cameras: cameras ?? this.cameras,
      currentCameraIndex: currentCameraIndex ?? this.currentCameraIndex,
    );
  }
}

/// Provider for managing camera controller lifecycle and operations.
@riverpod
class CameraControllerNotifier extends _$CameraControllerNotifier {
  CameraController? _controller;

  @override
  CameraState build() {
    ref.onDispose(_disposeController);
    return const CameraState();
  }

  /// Initializes the camera with the back camera as default.
  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        state = state.copyWith(
          error: const NoCamerasAvailableException(),
          isInitialized: false,
        );
        return;
      }

      // Find back camera, default to first available
      var cameraIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (cameraIndex == -1) cameraIndex = 0;

      state = state.copyWith(
        cameras: cameras,
        currentCameraIndex: cameraIndex,
        clearError: true,
      );

      await _initController(cameras[cameraIndex]);
    } catch (e) {
      state = state.copyWith(
        error: e,
        isInitialized: false,
      );
    }
  }

  Future<void> _initController(CameraDescription camera) async {
    await _disposeController();

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      state = state.copyWith(
        controller: _controller,
        isInitialized: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: e,
        isInitialized: false,
      );
    }
  }

  Future<void> _disposeController() async {
    if (_controller != null) {
      if (_controller!.value.isInitialized) {
        await _controller!.dispose();
      }
      _controller = null;
    }
  }

  /// Captures an image and returns the captured image data.
  Future<CapturedImage?> capture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      state = state.copyWith(
        error: const CameraNotInitializedException(),
      );
      return null;
    }

    if (_controller!.value.isTakingPicture || state.isCapturing) {
      state = state.copyWith(
        error: const CaptureInProgressException(),
      );
      return null;
    }

    state = state.copyWith(isCapturing: true, clearError: true);

    try {
      final xFile = await _controller!.takePicture();
      final capturedImage = CapturedImage(
        path: xFile.path,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(isCapturing: false);
      return capturedImage;
    } catch (e) {
      state = state.copyWith(
        isCapturing: false,
        error: CaptureFailedException(e.toString()),
      );
      return null;
    }
  }

  /// Flips between available cameras.
  Future<void> flipCamera() async {
    if (state.cameras.length < 2) return;

    final newIndex = (state.currentCameraIndex + 1) % state.cameras.length;
    state = state.copyWith(
      currentCameraIndex: newIndex,
      isInitialized: false,
    );

    await _initController(state.cameras[newIndex]);
  }

  /// Pauses the camera preview.
  Future<void> pausePreview() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.pausePreview();
      } catch (_) {
        // Ignore errors when pausing
      }
    }
  }

  /// Resumes the camera preview.
  Future<void> resumePreview() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.resumePreview();
      } catch (_) {
        // Ignore errors when resuming
      }
    }
  }

  /// Sets the flash mode on the camera.
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.setFlashMode(mode);
      } catch (_) {
        // Some cameras don't support flash mode changes
      }
    }
  }
}
