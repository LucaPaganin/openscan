import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Widget that displays the camera preview with correct aspect ratio.
///
/// Maintains the camera's native aspect ratio to prevent stretching.
class CameraPreviewWidget extends StatelessWidget {
  const CameraPreviewWidget({
    required this.controller,
    super.key,
  });

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cameraAspectRatio = controller.value.aspectRatio;

        // Calculate the size to fill the available space while maintaining
        // the camera's aspect ratio
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth * cameraAspectRatio,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }
}
