import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/camera_permission_service.dart';

part 'camera_permission_provider.g.dart';

/// State representing the camera permission status.
enum CameraPermissionState {
  /// Initial state, permission not yet checked.
  unknown,

  /// Permission has been granted.
  granted,

  /// Permission was denied but can still be requested.
  denied,

  /// Permission was permanently denied, must open settings.
  permanentlyDenied,
}

/// Provider for the [CameraPermissionService] instance.
@riverpod
CameraPermissionService cameraPermissionService(Ref ref) {
  return CameraPermissionService();
}

/// Provider for managing camera permission state.
///
/// Handles checking, requesting, and tracking camera permission status.
@riverpod
class CameraPermissionNotifier extends _$CameraPermissionNotifier {
  @override
  Future<CameraPermissionState> build() async {
    final service = ref.watch(cameraPermissionServiceProvider);
    return _mapStatusToState(await service.checkStatus());
  }

  /// Requests camera permission from the user.
  ///
  /// Updates the state based on the user's response.
  Future<void> requestPermission() async {
    state = const AsyncLoading();

    final service = ref.read(cameraPermissionServiceProvider);
    final status = await service.request();

    state = AsyncData(_mapStatusToState(status));
  }

  /// Refreshes the permission status.
  ///
  /// Useful after returning from app settings to check if user enabled permission.
  Future<void> refreshStatus() async {
    state = const AsyncLoading();

    final service = ref.read(cameraPermissionServiceProvider);
    final status = await service.checkStatus();

    state = AsyncData(_mapStatusToState(status));
  }

  /// Opens the app settings page.
  ///
  /// Returns true if settings were opened successfully.
  Future<bool> openSettings() async {
    final service = ref.read(cameraPermissionServiceProvider);
    return service.openSettings();
  }

  CameraPermissionState _mapStatusToState(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted || PermissionStatus.limited => CameraPermissionState.granted,
      PermissionStatus.denied => CameraPermissionState.denied,
      PermissionStatus.permanentlyDenied || PermissionStatus.restricted => CameraPermissionState.permanentlyDenied,
      _ => CameraPermissionState.unknown,
    };
  }
}
