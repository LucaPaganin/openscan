import 'package:flutter/material.dart';
import '../../domain/models/detected_document.dart';
import '../../domain/models/point.dart' as model;

/// Overlay widget that displays detected document boundaries.
class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({
    super.key,
    required this.previewSize,
    this.detection,
  });

  final DetectedDocument? detection;
  final Size previewSize;

  @override
  Widget build(BuildContext context) {
    if (detection == null) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: previewSize,
      painter: _DetectionPainter(
        corners: detection!.normalizedCorners,
        confidence: detection!.confidence,
      ),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  _DetectionPainter({
    required this.corners,
    required this.confidence,
  });

  final List<model.Point> corners;
  final double confidence;

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    final color = confidence > 0.6
        ? const Color(0xFF4CAF50) // Green
        : const Color(0xFFFFC107); // Yellow

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final handlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Convert normalized coordinates to actual pixels
    final points = corners
        .map((c) => Offset(
              c.x * size.width,
              c.y * size.height,
            ))
        .toList();

    // Draw filled area
    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();

    canvas
      ..drawPath(path, fillPaint)
      ..drawPath(path, linePaint);

    // Draw corner handles
    final whitePaint = Paint()..color = Colors.white;
    for (final point in points) {
      canvas
        ..drawCircle(point, 12, handlePaint)
        ..drawCircle(point, 10, whitePaint);
    }
  }

  @override
  bool shouldRepaint(_DetectionPainter oldDelegate) {
    return corners != oldDelegate.corners ||
        confidence != oldDelegate.confidence;
  }
}
