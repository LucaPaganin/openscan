import 'package:permission_handler/permission_handler.dart';

/// Service for handling camera permission requests and checks.
///
/// Provides methods to check the current permission status,
/// request permission from the user, and open app settings.
class CameraPermissionService {
  /// Checks the current camera permission status.
  ///
  /// Returns the current [PermissionStatus] for the camera.
  Future<PermissionStatus> checkStatus() async {
    return Permission.camera.status;
  }

  /// Requests camera permission from the user.
  ///
  /// Returns the resulting [PermissionStatus] after the user responds
  /// to the permission dialog.
  Future<PermissionStatus> request() async {
    return Permission.camera.request();
  }

  /// Opens the app settings page.
  ///
  /// Use this when permission has been permanently denied and the user
  /// needs to manually enable camera access from settings.
  ///
  /// Returns true if the settings page was opened successfully.
  Future<bool> openSettings() async {
    return openAppSettings();
  }

  /// Checks if permission is granted.
  Future<bool> isGranted() async {
    final status = await checkStatus();
    return status.isGranted;
  }

  /// Checks if permission is denied (can still request).
  Future<bool> isDenied() async {
    final status = await checkStatus();
    return status.isDenied;
  }

  /// Checks if permission is permanently denied (must go to settings).
  Future<bool> isPermanentlyDenied() async {
    final status = await checkStatus();
    return status.isPermanentlyDenied;
  }
}
