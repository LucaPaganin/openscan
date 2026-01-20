import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/features/camera/presentation/providers/camera_controller_provider.dart';

void main() {
  group('CameraState', () {
    test('initializes with default values', () {
      const state = CameraState();

      expect(state.controller, isNull);
      expect(state.isInitialized, false);
      expect(state.isCapturing, false);
      expect(state.error, isNull);
      expect(state.cameras, isEmpty);
      expect(state.currentCameraIndex, 0);
      expect(state.currentCamera, isNull);
      expect(state.canFlip, false);
    });

    test('currentCamera returns camera at currentCameraIndex', () {
      final cameras = [
        const CameraDescription(
          name: 'back',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
        const CameraDescription(
          name: 'front',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 270,
        ),
      ];

      final state = CameraState(
        cameras: cameras,
        currentCameraIndex: 0,
      );

      expect(state.currentCamera, cameras[0]);
      expect(state.currentCamera!.lensDirection, CameraLensDirection.back);
    });

    test('canFlip returns true when multiple cameras available', () {
      final cameras = [
        const CameraDescription(
          name: 'back',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
        const CameraDescription(
          name: 'front',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 270,
        ),
      ];

      final state = CameraState(cameras: cameras);

      expect(state.canFlip, true);
    });

    test('canFlip returns false when only one camera available', () {
      final cameras = [
        const CameraDescription(
          name: 'back',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
      ];

      final state = CameraState(cameras: cameras);

      expect(state.canFlip, false);
    });

    test('copyWith creates new state with updated values', () {
      const state = CameraState(
        isInitialized: false,
        isCapturing: false,
      );

      final newState = state.copyWith(
        isInitialized: true,
        isCapturing: true,
      );

      expect(newState.isInitialized, true);
      expect(newState.isCapturing, true);
      // Original state unchanged
      expect(state.isInitialized, false);
      expect(state.isCapturing, false);
    });

    test('copyWith with clearError removes error', () {
      final state = CameraState(
        error: Exception('test error'),
      );

      final newState = state.copyWith(clearError: true);

      expect(newState.error, isNull);
    });
  });

  group('Camera initialization logic', () {
    test('back camera is selected by default when available', () {
      final cameras = [
        const CameraDescription(
          name: 'front',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 270,
        ),
        const CameraDescription(
          name: 'back',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
      ];

      // Find back camera index (simulating initialization logic)
      var cameraIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (cameraIndex == -1) cameraIndex = 0;

      expect(cameraIndex, 1); // Back camera is at index 1
      expect(
        cameras[cameraIndex].lensDirection,
        CameraLensDirection.back,
      );
    });

    test('falls back to first camera when back camera unavailable', () {
      final cameras = [
        const CameraDescription(
          name: 'front',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 270,
        ),
        const CameraDescription(
          name: 'external',
          lensDirection: CameraLensDirection.external,
          sensorOrientation: 0,
        ),
      ];

      // Find back camera index (simulating initialization logic)
      var cameraIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (cameraIndex == -1) cameraIndex = 0;

      expect(cameraIndex, 0); // Falls back to first camera
      expect(
        cameras[cameraIndex].lensDirection,
        CameraLensDirection.front,
      );
    });
  });
}
