import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openscan/features/gallery/data/repositories/document_repository.dart';
import 'package:openscan/features/gallery/domain/services/document_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock PathProviderPlatform for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentService', () {
    late DocumentService service;
    late DocumentRepository repository;
    late Directory testDir;

    setUp(() async {
      // Set up mock path provider
      PathProviderPlatform.instance = MockPathProviderPlatform();

      repository = DocumentRepository();
      service = DocumentService(repository);

      // Clean up test directory before each test
      testDir = Directory('${Directory.systemTemp.path}/scans');
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    tearDown(() async {
      // Clean up test directory after each test
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    File createTestImage() {
      // Create a simple test image
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(255, 0, 0));
      final bytes = img.encodeJpg(image);

      final tempFile = File('${Directory.systemTemp.path}/test_image.jpg')
        ..writeAsBytesSync(bytes);
      return tempFile;
    }

    test('saveCapture() creates document with correct title format', () async {
      // Arrange
      final testImage = createTestImage();

      // Act
      final document = await service.saveCapture(testImage.path);

      // Assert
      expect(document.id, isNotEmpty);
      expect(document.title, matches(r'Scan \d{4}-\d{2}-\d{2} \d{2}:\d{2}'));
      expect(document.imagePath, isNotEmpty);
      expect(document.thumbnailPath, isNotEmpty);
      expect(await File(document.imagePath).exists(), true);
      expect(await File(document.thumbnailPath!).exists(), true);

      // Verify temp file was deleted
      expect(await testImage.exists(), false);
    });

    test('saveCapture() returns valid document for newly captured image', () async {
      // Arrange
      final testImage = createTestImage();

      // Act
      final document = await service.saveCapture(testImage.path);

      // Assert - Verify document is properly saved with all required fields
      expect(document.id, isNotEmpty);
      expect(document.title, isNotEmpty);
      expect(document.createdAt, isNotNull);
      expect(document.updatedAt, isNotNull);
      expect(document.createdAt, equals(document.updatedAt));
    });

    test('saveCapture() generates thumbnail with correct dimensions', () async {
      // Arrange
      final testImage = createTestImage();

      // Act
      final document = await service.saveCapture(testImage.path);

      // Assert
      final thumbBytes = await File(document.thumbnailPath!).readAsBytes();
      final thumbImage = img.decodeImage(thumbBytes);

      expect(thumbImage, isNotNull);
      expect(thumbImage!.width, 300);
      expect(thumbImage.height, lessThanOrEqualTo(300));
    });

    test('saveCapture() moves image from temp to permanent storage', () async {
      // Arrange
      final testImage = createTestImage();
      final originalPath = testImage.path;

      // Act
      final document = await service.saveCapture(originalPath);

      // Assert
      expect(await File(originalPath).exists(), false);
      expect(await File(document.imagePath).exists(), true);
    });
  });
}
