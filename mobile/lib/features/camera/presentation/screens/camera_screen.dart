import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/camera_permission_provider.dart';
import '../widgets/camera_loading_view.dart';
import '../widgets/camera_permission_denied_view.dart';
import '../widgets/camera_view.dart';

/// Main camera screen that handles permission flow and displays camera preview.
///
/// On first launch, requests camera permission. Displays appropriate UI based
/// on permission state:
/// - Loading while checking permission
/// - Permission denied view with action button
/// - Camera preview when permission is granted
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh permission status when app comes back to foreground
    // (user might have changed permission in settings)
    if (state == AppLifecycleState.resumed) {
      ref.read(cameraPermissionNotifierProvider.notifier).refreshStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionState = ref.watch(cameraPermissionNotifierProvider);

    return Scaffold(
      // Hide app bar for full-screen camera preview when permission granted
      appBar: permissionState.maybeWhen(
        data: (state) =>
            state == CameraPermissionState.granted ? null : _buildAppBar(),
        orElse: _buildAppBar,
      ),
      body: permissionState.when(
        loading: () => const CameraLoadingView(
          message: 'Checking camera permission...',
        ),
        error: (error, stackTrace) => _buildErrorView(context, error),
        data: (state) => _buildContentForState(context, state),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Camera'),
    );
  }

  Widget _buildContentForState(
    BuildContext context,
    CameraPermissionState state,
  ) {
    switch (state) {
      case CameraPermissionState.granted:
        return CameraView(
          onImageCaptured: _handleImageCaptured,
        );

      case CameraPermissionState.denied:
        return CameraPermissionDeniedView(
          isPermanentlyDenied: false,
          onActionPressed: () {
            ref
                .read(cameraPermissionNotifierProvider.notifier)
                .requestPermission();
          },
        );

      case CameraPermissionState.permanentlyDenied:
        return CameraPermissionDeniedView(
          isPermanentlyDenied: true,
          onActionPressed: () {
            ref.read(cameraPermissionNotifierProvider.notifier).openSettings();
          },
        );

      case CameraPermissionState.unknown:
        // Auto-request permission on first load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(cameraPermissionNotifierProvider.notifier)
              .requestPermission();
        });
        return const CameraLoadingView(
          message: 'Requesting camera permission...',
        );
    }
  }

  void _handleImageCaptured(String imagePath) {
    // For now, just log the path. In future epics, this will navigate
    // to the edge detection or document cropping screen.
    debugPrint('Image captured at: $imagePath');
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
              'Something went wrong',
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
                ref.invalidate(cameraPermissionNotifierProvider);
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
