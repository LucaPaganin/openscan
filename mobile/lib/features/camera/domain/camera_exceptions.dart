/// Exception thrown when camera is not initialized.
class CameraNotInitializedException implements Exception {
  const CameraNotInitializedException([this.message = 'Camera is not initialized']);

  final String message;

  @override
  String toString() => 'CameraNotInitializedException: $message';
}

/// Exception thrown when a capture is already in progress.
class CaptureInProgressException implements Exception {
  const CaptureInProgressException([this.message = 'Capture already in progress']);

  final String message;

  @override
  String toString() => 'CaptureInProgressException: $message';
}

/// Exception thrown when image capture fails.
class CaptureFailedException implements Exception {
  const CaptureFailedException(this.message);

  final String message;

  @override
  String toString() => 'CaptureFailedException: $message';
}

/// Exception thrown when no cameras are available on the device.
class NoCamerasAvailableException implements Exception {
  const NoCamerasAvailableException([
    this.message = 'No cameras available on this device',
  ]);

  final String message;

  @override
  String toString() => 'NoCamerasAvailableException: $message';
}
