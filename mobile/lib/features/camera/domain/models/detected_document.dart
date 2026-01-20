import 'package:flutter/material.dart';
import 'point.dart';

/// Represents a detected document with its four corners and confidence level.
class DetectedDocument {
  const DetectedDocument({
    required this.corners,
    required this.confidence,
    required this.imageSize,
  }) : assert(corners.length == 4, 'DetectedDocument must have exactly 4 corners');

  /// Four corners in clockwise order: top-left, top-right, bottom-right, bottom-left
  final List<Point> corners;

  /// Confidence level from 0.0 to 1.0
  final double confidence;

  /// Size of the source image
  final Size imageSize;

  /// Returns true if confidence is above the high-confidence threshold (0.6)
  bool get isHighConfidence => confidence > 0.6;

  /// Converts corners to normalized coordinates (0.0 to 1.0)
  List<Point> get normalizedCorners {
    return corners
        .map((c) => Point(
              c.x / imageSize.width,
              c.y / imageSize.height,
            ))
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectedDocument &&
          runtimeType == other.runtimeType &&
          _listEquals(corners, other.corners) &&
          confidence == other.confidence &&
          imageSize == other.imageSize;

  @override
  int get hashCode => corners.hashCode ^ confidence.hashCode ^ imageSize.hashCode;

  bool _listEquals(List<Point> a, List<Point> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'DetectedDocument(corners: $corners, confidence: $confidence, imageSize: $imageSize)';
}
