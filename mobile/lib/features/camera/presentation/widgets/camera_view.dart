import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/camera_controller_provider.dart';
import '../providers/flash_mode_provider.dart';
import 'camera_controls_bar.dart';
import 'camera_loading_view.dart';
import 'camera_preview.dart';

/// Complete camera view with preview and controls bar.
///
/// Handles camera initialization, lifecycle management, flash control,
/// camera flip, and capture flow.
class CameraView extends ConsumerStatefulWidget {
  const CameraView({
    super.key,
    this.onImageCaptured,
  });

  /// Callback when an image is successfully captured.
  final void Function(String imagePath)? onImageCaptured;

  @override
  ConsumerState<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends ConsumerState<CameraView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize camera after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraControllerProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraNotifier = ref.read(cameraControllerProvider.notifier);

    switch (state) {
      case AppLifecycleState.inactive:
        cameraNotifier.pausePreview();
      case AppLifecycleState.resumed:
        cameraNotifier.resumePreview();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _handleCapture() async {
    // Apply flash mode before capture
    final flashMode = ref.read(flashModeProvider);
    await ref
        .read(cameraControllerProvider.notifier)
        .setFlashMode(flashMode);

    final capturedImage = await ref
        .read(cameraControllerProvider.notifier)
        .capture();

    if (capturedImage != null && mounted) {
      widget.onImageCaptured?.call(capturedImage.path);

      // Show a brief success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image captured'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleFlashToggle() {
    ref.read(flashModeProvider.notifier).cycle();
    // Apply the new flash mode to the camera
    final newFlashMode = ref.read(flashModeProvider);
    ref
        .read(cameraControllerProvider.notifier)
        .setFlashMode(newFlashMode);
  }

  Future<void> _handleCameraFlip() async {
    await ref.read(cameraControllerProvider.notifier).flipCamera();
    // Re-apply flash mode after flip
    final flashMode = ref.read(flashModeProvider);
    await ref
        .read(cameraControllerProvider.notifier)
        .setFlashMode(flashMode);
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraControllerProvider);
    final flashMode = ref.watch(flashModeProvider);

    // Show loading while camera is initializing
    if (!cameraState.isInitialized || cameraState.controller == null) {
      return const CameraLoadingView(
        message: 'Initializing camera...',
      );
    }

    // Show error if camera failed
    if (cameraState.error != null && !cameraState.isInitialized) {
      return _buildErrorView(context, cameraState.error!);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        CameraPreviewWidget(controller: cameraState.controller!),

        // Controls bar at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CameraControlsBar(
            onCapture: _handleCapture,
            onFlashToggle: _handleFlashToggle,
            onCameraFlip: _handleCameraFlip,
            flashMode: flashMode,
            isCapturing: cameraState.isCapturing,
            canFlip: cameraState.canFlip,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, Object error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Error',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                ref.read(cameraControllerProvider.notifier).initialize();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
