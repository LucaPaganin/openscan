import 'package:flutter/material.dart';

/// Button for switching between front and back cameras.
///
/// Displays a flip camera icon and can be disabled when only one camera
/// is available.
class CameraFlipButton extends StatelessWidget {
  const CameraFlipButton({
    required this.onPressed,
    super.key,
    this.canFlip = true,
  });

  final VoidCallback onPressed;
  final bool canFlip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: canFlip ? onPressed : null,
      icon: Icon(
        Icons.flip_camera_ios,
        color: canFlip ? Colors.white : Colors.white38,
        size: 28,
      ),
      tooltip: 'Switch camera',
    );
  }
}
