import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/errors/document_exceptions.dart';
import 'package:openscan/features/gallery/data/repositories/document_repository.dart';
import 'package:openscan/features/gallery/domain/models/document.dart';
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

  group('DocumentRepository', () {
    late DocumentRepository repository;
    late Directory testDir;

    setUp(() async {
      // Set up mock path provider
      PathProviderPlatform.instance = MockPathProviderPlatform();

      repository = DocumentRepository();

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

    test('save() persists document and can be retrieved with getAll()', () async {
      // Arrange
      final testDate = DateTime(2024, 1, 15, 10, 30);
      final document = Document(
        id: 'test-doc-1',
        title: 'Test Document',
        imagePath: '/path/to/image.jpg',
        thumbnailPath: '/path/to/thumb.jpg',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act
      await repository.save(document);
      final documents = await repository.getAll();

      // Assert
      expect(documents.length, 1);
      expect(documents.first.id, 'test-doc-1');
      expect(documents.first.title, 'Test Document');
      expect(documents.first.imagePath, '/path/to/image.jpg');
    });

    test('delete() removes document and associated image files', () async {
      // Arrange
      final testDate = DateTime.now();

      // Create test image files
      final imagePath = await repository.getImageStoragePath('test-image.jpg');
      final thumbPath = await repository.getImageStoragePath('test-thumb.jpg');
      await File(imagePath).create(recursive: true);
      await File(thumbPath).create(recursive: true);

      final document = Document(
        id: 'test-doc-2',
        title: 'Test Document to Delete',
        imagePath: imagePath,
        thumbnailPath: thumbPath,
        createdAt: testDate,
        updatedAt: testDate,
      );

      await repository.save(document);

      // Verify files exist
      expect(await File(imagePath).exists(), true);
      expect(await File(thumbPath).exists(), true);

      // Act
      await repository.delete('test-doc-2');

      // Assert
      final documents = await repository.getAll();
      expect(documents.isEmpty, true);
      expect(await File(imagePath).exists(), false);
      expect(await File(thumbPath).exists(), false);
    });

    test('getAll() returns empty list when no documents exist', () async {
      // Act
      final documents = await repository.getAll();

      // Assert
      expect(documents, isEmpty);
    });

    test('getById() returns null when document not found', () async {
      // Act
      final document = await repository.getById('non-existent-id');

      // Assert
      expect(document, isNull);
    });

    test('delete() throws DocumentNotFoundException for non-existent document', () async {
      // Act & Assert
      expect(
        () => repository.delete('non-existent-id'),
        throwsA(isA<DocumentNotFoundException>()),
      );
    });

    test('save() updates existing document when id matches', () async {
      // Arrange
      final testDate = DateTime.now();
      final document = Document(
        id: 'test-doc-3',
        title: 'Original Title',
        imagePath: '/path/to/image.jpg',
        thumbnailPath: '/path/to/thumb.jpg',
        createdAt: testDate,
        updatedAt: testDate,
      );

      await repository.save(document);

      final updatedDocument = document.copyWith(
        title: 'Updated Title',
        updatedAt: DateTime.now(),
      );

      // Act
      await repository.save(updatedDocument);
      final documents = await repository.getAll();

      // Assert
      expect(documents.length, 1);
      expect(documents.first.title, 'Updated Title');
    });
  });
}
