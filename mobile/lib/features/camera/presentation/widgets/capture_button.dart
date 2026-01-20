import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A circular capture button with press animation and haptic feedback.
///
/// Displays a 72x72 white circle with an inner 60x60 bordered circle.
/// Shows a scale animation when pressed and provides haptic feedback.
/// Changes color to green when a document is detected.
class CaptureButton extends StatefulWidget {
  const CaptureButton({
    required this.onPressed,
    super.key,
    this.isCapturing = false,
    this.isDocumentDetected = false,
  });

  /// Callback when the button is pressed.
  final VoidCallback onPressed;

  /// Whether a capture is currently in progress.
  /// When true, the button shows a pressed state and ignores taps.
  final bool isCapturing;

  /// Whether a document is currently detected with high confidence.
  /// When true, the button changes color to green.
  final bool isDocumentDetected;

  @override
  State<CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<CaptureButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.9).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isCapturing) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isCapturing) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    if (widget.isCapturing) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTap() {
    if (widget.isCapturing) return;
    // Trigger haptic feedback
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final showPressed = widget.isCapturing || _isPressed;
    final buttonColor = widget.isDocumentDetected
        ? const Color(0xFF4CAF50) // Green when ready
        : Colors.white;
    final borderColor = widget.isDocumentDetected
        ? Colors.white
        : Colors.black12;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isCapturing ? 0.9 : _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: showPressed ? buttonColor.withValues(alpha: 0.7) : buttonColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: 2,
                ),
              ),
              child: widget.isCapturing
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.isDocumentDetected
                            ? Colors.white
                            : Colors.black54,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
