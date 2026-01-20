import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/camera_controller_provider.dart';
import 'camera_loading_view.dart';
import 'camera_preview.dart';
import 'capture_button.dart';

/// Complete camera view with preview and capture button.
///
/// Handles camera initialization, lifecycle management, and capture flow.
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
      ref.read(cameraControllerNotifierProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraNotifier = ref.read(cameraControllerNotifierProvider.notifier);

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
    final capturedImage = await ref
        .read(cameraControllerNotifierProvider.notifier)
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

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraControllerNotifierProvider);

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

        // Capture button at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildControlsBar(cameraState),
        ),
      ],
    );
  }

  Widget _buildControlsBar(CameraState cameraState) {
    return ColoredBox(
      color: Colors.black.withAlpha(128),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CaptureButton(
              onPressed: _handleCapture,
              isCapturing: cameraState.isCapturing,
            ),
          ),
        ),
      ),
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
                ref.read(cameraControllerNotifierProvider.notifier).initialize();
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
