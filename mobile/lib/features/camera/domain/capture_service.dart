import 'package:camera/camera.dart';

import 'camera_exceptions.dart';
import 'models/captured_image.dart';

/// Service for capturing images from the camera.
///
/// Handles the capture process including validation and error handling.
class CaptureService {
  CaptureService(this.controller);

  final CameraController controller;

  /// Captures an image from the camera.
  ///
  /// Returns a [CapturedImage] with the path to the captured image.
  /// Throws [CameraNotInitializedException] if camera is not initialized.
  /// Throws [CaptureInProgressException] if capture is already in progress.
  /// Throws [CaptureFailedException] if capture fails.
  Future<CapturedImage> capture() async {
    if (!controller.value.isInitialized) {
      throw const CameraNotInitializedException();
    }

    if (controller.value.isTakingPicture) {
      throw const CaptureInProgressException();
    }

    try {
      final file = await controller.takePicture();
      return CapturedImage(
        path: file.path,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw CaptureFailedException(e.toString());
    }
  }
}
