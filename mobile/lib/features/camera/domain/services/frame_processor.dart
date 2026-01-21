import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/detected_document.dart';
import 'edge_detection_service.dart';

/// Processes camera frames for edge detection in real-time.
///
/// Uses the camera's image stream for efficient frame processing
/// instead of taking pictures repeatedly.
class FrameProcessor {
  FrameProcessor({
    required EdgeDetectionService edgeService,
    Duration frameInterval = const Duration(milliseconds: 150),
  })  : _edgeService = edgeService,
        _frameInterval = frameInterval;

  final EdgeDetectionService _edgeService;
  final Duration _frameInterval;

  bool _isProcessing = false;
  bool _isStreaming = false;
  DateTime _lastProcessedTime = DateTime.now();
  StreamController<DetectedDocument?>? _resultController;

  Stream<DetectedDocument?> get detectionStream {
    _resultController ??= StreamController<DetectedDocument?>.broadcast();
    return _resultController!.stream;
  }

  void startProcessing(CameraController controller) {
    if (_isStreaming) return;

    _isStreaming = true;
    _lastProcessedTime = DateTime.now();

    debugPrint('Starting image stream for edge detection');
    try {
      controller.startImageStream(_processFrame);
      debugPrint('Image stream started successfully');
    } catch (e) {
      debugPrint('Failed to start image stream: $e');
      _isStreaming = false;
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    // Skip if already processing or if not enough time has passed
    if (_isProcessing) return;

    final now = DateTime.now();
    if (now.difference(_lastProcessedTime) < _frameInterval) {
      return;
    }

    _isProcessing = true;
    _lastProcessedTime = now;

    try {
      debugPrint('Processing frame: ${image.width}x${image.height}, format: ${image.format.group}');
      // Convert CameraImage to bytes that OpenCV can decode
      final bytes = await _convertCameraImageToJpeg(image);
      debugPrint('Converted to JPEG: ${bytes?.length ?? 0} bytes');
      if (bytes != null) {
        final result = await _edgeService.detectEdges(bytes);
        debugPrint('Detection result: $result');
        _resultController?.add(result);
      }
    } catch (e) {
      debugPrint('Frame processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Converts a CameraImage to JPEG bytes for OpenCV processing.
  ///
  /// CameraImage format varies by platform:
  /// - Android: YUV420 (NV21 or YUV420_888)
  /// - iOS: BGRA8888
  Future<Uint8List?> _convertCameraImageToJpeg(CameraImage image) async {
    try {
      // Use compute to run conversion off the main isolate
      return await compute(_convertImageToJpeg, _CameraImageData.fromImage(image));
    } catch (e) {
      debugPrint('Image conversion error: $e');
      return null;
    }
  }

  void stopProcessing() {
    _isStreaming = false;
    _isProcessing = false;
  }

  void dispose() {
    stopProcessing();
    _resultController?.close();
    _resultController = null;
  }
}

/// Data class to pass camera image data to isolate.
class _CameraImageData {
  _CameraImageData({
    required this.width,
    required this.height,
    required this.planes,
    required this.format,
  });

  factory _CameraImageData.fromImage(CameraImage image) {
    return _CameraImageData(
      width: image.width,
      height: image.height,
      planes: image.planes
          .map((p) => _PlaneData(
                bytes: Uint8List.fromList(p.bytes),
                bytesPerRow: p.bytesPerRow,
                bytesPerPixel: p.bytesPerPixel,
              ))
          .toList(),
      format: image.format.group,
    );
  }

  final int width;
  final int height;
  final List<_PlaneData> planes;
  final ImageFormatGroup format;
}

class _PlaneData {
  _PlaneData({
    required this.bytes,
    required this.bytesPerRow,
    this.bytesPerPixel,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int? bytesPerPixel;
}

/// Converts camera image data to JPEG bytes in an isolate.
Uint8List? _convertImageToJpeg(_CameraImageData data) {
  try {
    img.Image? image;

    if (data.format == ImageFormatGroup.yuv420) {
      // Android YUV420 format
      image = _convertYUV420ToImage(data);
    } else if (data.format == ImageFormatGroup.bgra8888) {
      // iOS BGRA format
      image = _convertBGRA8888ToImage(data);
    } else {
      // Unknown format - try BGRA as fallback
      image = _convertBGRA8888ToImage(data);
    }

    if (image == null) return null;

    // Scale down for faster processing (edge detection doesn't need full resolution)
    final scaledImage = img.copyResize(
      image,
      width: 640,
      interpolation: img.Interpolation.nearest,
    );

    // Encode to JPEG
    return Uint8List.fromList(img.encodeJpg(scaledImage, quality: 80));
  } catch (e) {
    return null;
  }
}

/// Converts YUV420 (Android) to img.Image.
img.Image? _convertYUV420ToImage(_CameraImageData data) {
  try {
    final yPlane = data.planes[0];
    final uPlane = data.planes[1];
    final vPlane = data.planes[2];

    final image = img.Image(width: data.width, height: data.height);

    for (var y = 0; y < data.height; y++) {
      for (var x = 0; x < data.width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2);

        final yValue = yPlane.bytes[yIndex];
        final uValue = uPlane.bytes[uvIndex];
        final vValue = vPlane.bytes[uvIndex];

        // YUV to RGB conversion
        final r = (yValue + 1.370705 * (vValue - 128)).round().clamp(0, 255);
        final g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128))
            .round()
            .clamp(0, 255);
        final b = (yValue + 1.732446 * (uValue - 128)).round().clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  } catch (e) {
    return null;
  }
}

/// Converts BGRA8888 (iOS) to img.Image.
img.Image? _convertBGRA8888ToImage(_CameraImageData data) {
  try {
    final plane = data.planes[0];
    final image = img.Image(width: data.width, height: data.height);

    for (var y = 0; y < data.height; y++) {
      for (var x = 0; x < data.width; x++) {
        final index = y * plane.bytesPerRow + x * 4;
        final b = plane.bytes[index];
        final g = plane.bytes[index + 1];
        final r = plane.bytes[index + 2];
        // Skip alpha at index + 3

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  } catch (e) {
    return null;
  }
}
