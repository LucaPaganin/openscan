import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'camera_flip_button.dart';
import 'capture_button.dart';
import 'flash_toggle_button.dart';

/// Camera controls bar with flash, capture, and flip buttons.
///
/// Layout: [Flash] — [Capture] — [Flip]
/// Semi-transparent dark background for visibility.
/// Respects safe area (notch, home indicator).
class CameraControlsBar extends StatelessWidget {
  const CameraControlsBar({
    required this.onCapture,
    required this.onFlashToggle,
    required this.onCameraFlip,
    required this.flashMode,
    super.key,
    this.isCapturing = false,
    this.canFlip = true,
  });

  final VoidCallback onCapture;
  final VoidCallback onFlashToggle;
  final VoidCallback onCameraFlip;
  final FlashMode flashMode;
  final bool isCapturing;
  final bool canFlip;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withAlpha(128),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Flash button
              FlashToggleButton(
                flashMode: flashMode,
                onPressed: onFlashToggle,
              ),

              // Capture button
              CaptureButton(
                onPressed: onCapture,
                isCapturing: isCapturing,
              ),

              // Flip button
              CameraFlipButton(
                onPressed: onCameraFlip,
                canFlip: canFlip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
