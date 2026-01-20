import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../../../../core/errors/edge_detection_exceptions.dart';
import '../models/detected_document.dart';
import '../models/point.dart';

/// Service for detecting document edges in images using OpenCV.
class EdgeDetectionService {
  /// Detects document edges in the given image bytes.
  /// Returns four corners in clockwise order starting from top-left,
  /// or null if no document detected.
  Future<DetectedDocument?> detectEdges(Uint8List imageBytes) async {
    try {
      // Decode image
      final mat = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
      if (mat.isEmpty) return null;

      final imageWidth = mat.cols;
      final imageHeight = mat.rows;

      // Convert to grayscale
      final gray = cv.cvtColor(mat, cv.COLOR_BGR2GRAY);

      // Apply Gaussian blur to reduce noise
      final blurred = cv.gaussianBlur(gray, (5, 5), 0);

      // Edge detection using Canny
      final edges = cv.canny(blurred, 75, 200);

      // Find contours
      final contours = cv.findContours(
        edges,
        cv.RETR_LIST,
        cv.CHAIN_APPROX_SIMPLE,
      );

      // Find the largest quadrilateral contour
      final quad = _findLargestQuadrilateral(
        contours.$1,
        imageWidth,
        imageHeight,
      );

      // Cleanup
      mat.dispose();
      gray.dispose();
      blurred.dispose();
      edges.dispose();

      return quad;
    } catch (e) {
      throw EdgeDetectionException('Failed to detect edges: $e');
    }
  }

  DetectedDocument? _findLargestQuadrilateral(
    cv.VecVecPoint contours,
    int imageWidth,
    int imageHeight,
  ) {
    final imageArea = (imageWidth * imageHeight).toDouble();
    final minArea = imageArea * 0.1; // Document must be at least 10% of frame
    final maxArea = imageArea * 0.95; // Document can't be larger than 95%

    DetectedDocument? bestDocument;
    double bestArea = 0;

    for (var i = 0; i < contours.length; i++) {
      final contour = contours[i];
      final area = cv.contourArea(contour);

      // Skip if too small or too large
      if (area < minArea || area > maxArea) continue;

      // Approximate contour to polygon
      final peri = cv.arcLength(contour, true);
      final approx = cv.approxPolyDP(contour, 0.02 * peri, true);

      // We want exactly 4 corners (quadrilateral)
      if (approx.length == 4 && area > bestArea) {
        // Verify it's convex
        if (cv.isContourConvex(approx)) {
          bestArea = area;
          bestDocument = DetectedDocument(
            corners: _orderCorners(approx, imageWidth, imageHeight),
            confidence: _calculateConfidence(area, imageArea),
            imageSize: Size(imageWidth.toDouble(), imageHeight.toDouble()),
          );
        }
      }
    }

    return bestDocument;
  }

  /// Orders corners: top-left, top-right, bottom-right, bottom-left
  List<Point> _orderCorners(cv.VecPoint approx, int width, int height) {
    final points = List.generate(
      approx.length,
      (i) {
        final p = approx[i];
        return Point(p.x.toDouble(), p.y.toDouble());
      },
    );

    // Find top-left (smallest sum of coordinates)
    // Find bottom-right (largest sum of coordinates)
    points.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
    final topLeft = points[0];
    final bottomRight = points[3];

    // Find top-right (largest difference x - y)
    // Find bottom-left (smallest difference x - y)
    final sortedByDiff = List<Point>.from(points)
      ..sort((a, b) => (b.x - b.y).compareTo(a.x - a.y));
    final topRight = sortedByDiff[0];
    final bottomLeft = sortedByDiff[3];

    return [topLeft, topRight, bottomRight, bottomLeft];
  }

  double _calculateConfidence(double contourArea, double imageArea) {
    // Confidence based on how well-defined the contour is
    // Larger documents relative to frame = higher confidence
    final ratio = contourArea / imageArea;
    return (ratio * 2).clamp(0.0, 1.0);
  }
}
