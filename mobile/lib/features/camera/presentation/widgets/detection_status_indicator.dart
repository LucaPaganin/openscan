import 'package:flutter/material.dart';
import '../../domain/models/detected_document.dart';

/// Widget that displays the current detection status.
class DetectionStatusIndicator extends StatelessWidget {
  const DetectionStatusIndicator({super.key, this.detection});

  final DetectedDocument? detection;

  @override
  Widget build(BuildContext context) {
    final status = _getStatus();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(status.text),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              status.text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _DetectionStatus _getStatus() {
    if (detection == null) {
      return const _DetectionStatus(
        text: 'Position document',
        icon: Icons.crop_free,
        color: Colors.grey,
      );
    }

    if (detection!.isHighConfidence) {
      return const _DetectionStatus(
        text: 'Ready!',
        icon: Icons.check_circle,
        color: Color(0xFF4CAF50),
      );
    }

    return const _DetectionStatus(
      text: 'Hold steady',
      icon: Icons.center_focus_strong,
      color: Color(0xFFFFC107),
    );
  }
}

class _DetectionStatus {
  const _DetectionStatus({
    required this.text,
    required this.icon,
    required this.color,
  });

  final String text;
  final IconData icon;
  final Color color;
}
