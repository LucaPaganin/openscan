import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Button for toggling flash mode.
///
/// Displays the appropriate icon based on current flash mode:
/// - Off: flash_off
/// - Auto: flash_auto
/// - On: flash_on
class FlashToggleButton extends StatelessWidget {
  const FlashToggleButton({
    required this.flashMode,
    required this.onPressed,
    super.key,
  });

  final FlashMode flashMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        _iconForMode(flashMode),
        color: Colors.white,
        size: 28,
      ),
      tooltip: _tooltipForMode(flashMode),
    );
  }

  IconData _iconForMode(FlashMode mode) {
    return switch (mode) {
      FlashMode.off => Icons.flash_off,
      FlashMode.auto => Icons.flash_auto,
      FlashMode.always => Icons.flash_on,
      FlashMode.torch => Icons.flash_on,
    };
  }

  String _tooltipForMode(FlashMode mode) {
    return switch (mode) {
      FlashMode.off => 'Flash off',
      FlashMode.auto => 'Flash auto',
      FlashMode.always => 'Flash on',
      FlashMode.torch => 'Flash torch',
    };
  }
}
