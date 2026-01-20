import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/features/camera/domain/camera_exceptions.dart';
import 'package:openscan/features/camera/domain/models/captured_image.dart';

void main() {
  group('CameraExceptions', () {
    test('CameraNotInitializedException has default message', () {
      const exception = CameraNotInitializedException();
      expect(exception.message, 'Camera is not initialized');
      expect(exception.toString(),
          'CameraNotInitializedException: Camera is not initialized');
    });

    test('CameraNotInitializedException accepts custom message', () {
      const exception = CameraNotInitializedException('Custom error');
      expect(exception.message, 'Custom error');
      expect(
          exception.toString(), 'CameraNotInitializedException: Custom error');
    });

    test('CaptureInProgressException has default message', () {
      const exception = CaptureInProgressException();
      expect(exception.message, 'Capture already in progress');
      expect(exception.toString(),
          'CaptureInProgressException: Capture already in progress');
    });

    test('CaptureInProgressException accepts custom message', () {
      const exception = CaptureInProgressException('Already capturing');
      expect(exception.message, 'Already capturing');
      expect(
          exception.toString(), 'CaptureInProgressException: Already capturing');
    });

    test('CaptureFailedException requires message', () {
      const exception = CaptureFailedException('Disk full');
      expect(exception.message, 'Disk full');
      expect(exception.toString(), 'CaptureFailedException: Disk full');
    });

    test('NoCamerasAvailableException has default message', () {
      const exception = NoCamerasAvailableException();
      expect(exception.message, 'No cameras available on this device');
      expect(exception.toString(),
          'NoCamerasAvailableException: No cameras available on this device');
    });

    test('NoCamerasAvailableException accepts custom message', () {
      const exception = NoCamerasAvailableException('No hardware camera');
      expect(exception.message, 'No hardware camera');
      expect(exception.toString(),
          'NoCamerasAvailableException: No hardware camera');
    });
  });

  group('CapturedImage', () {
    test('creates instance with path and timestamp', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final image = CapturedImage(
        path: '/tmp/image.jpg',
        timestamp: timestamp,
      );

      expect(image.path, '/tmp/image.jpg');
      expect(image.timestamp, timestamp);
    });

    test('toString returns readable format', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final image = CapturedImage(
        path: '/tmp/image.jpg',
        timestamp: timestamp,
      );

      expect(
        image.toString(),
        'CapturedImage(path: /tmp/image.jpg, timestamp: 2024-01-15 10:30:00.000)',
      );
    });

    test('equality works correctly for same values', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final image1 = CapturedImage(path: '/tmp/image.jpg', timestamp: timestamp);
      final image2 = CapturedImage(path: '/tmp/image.jpg', timestamp: timestamp);

      expect(image1, equals(image2));
      expect(image1.hashCode, equals(image2.hashCode));
    });

    test('equality returns false for different paths', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final image1 = CapturedImage(path: '/tmp/image1.jpg', timestamp: timestamp);
      final image2 = CapturedImage(path: '/tmp/image2.jpg', timestamp: timestamp);

      expect(image1, isNot(equals(image2)));
    });

    test('equality returns false for different timestamps', () {
      final image1 = CapturedImage(
        path: '/tmp/image.jpg',
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );
      final image2 = CapturedImage(
        path: '/tmp/image.jpg',
        timestamp: DateTime(2024, 1, 15, 10, 31),
      );

      expect(image1, isNot(equals(image2)));
    });

    test('equality returns false for non-CapturedImage objects', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final image = CapturedImage(path: '/tmp/image.jpg', timestamp: timestamp);

      // ignore: unrelated_type_equality_checks
      expect(image == 'not an image', false);
    });
  });
}
