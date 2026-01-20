import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/features/gallery/domain/models/document.dart';

void main() {
  group('Document Model', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    test('Document serializes to JSON correctly', () {
      // Arrange
      final document = Document(
        id: 'test-id-123',
        title: 'Test Document',
        imagePath: '/path/to/image.jpg',
        thumbnailPath: '/path/to/thumb.jpg',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act
      final json = document.toJson();

      // Assert
      expect(json['id'], 'test-id-123');
      expect(json['title'], 'Test Document');
      expect(json['imagePath'], '/path/to/image.jpg');
      expect(json['thumbnailPath'], '/path/to/thumb.jpg');
      expect(json['createdAt'], testDate.toIso8601String());
      expect(json['updatedAt'], testDate.toIso8601String());
    });

    test('Document deserializes from JSON correctly, including null thumbnailPath', () {
      // Arrange
      final jsonWithNull = {
        'id': 'test-id-456',
        'title': 'Another Document',
        'imagePath': '/path/to/another.jpg',
        'thumbnailPath': null,
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
      };

      // Act
      final document = Document.fromJson(jsonWithNull);

      // Assert
      expect(document.id, 'test-id-456');
      expect(document.title, 'Another Document');
      expect(document.imagePath, '/path/to/another.jpg');
      expect(document.thumbnailPath, isNull);
      expect(document.createdAt, testDate);
      expect(document.updatedAt, testDate);
    });

    test('Document copyWith creates new instance with updated fields', () {
      // Arrange
      final original = Document(
        id: 'test-id',
        title: 'Original Title',
        imagePath: '/original.jpg',
        thumbnailPath: '/thumb.jpg',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final newDate = DateTime(2024, 1, 20, 15, 45);

      // Act
      final updated = original.copyWith(
        title: 'Updated Title',
        updatedAt: newDate,
      );

      // Assert
      expect(updated.id, 'test-id');
      expect(updated.title, 'Updated Title');
      expect(updated.imagePath, '/original.jpg');
      expect(updated.thumbnailPath, '/thumb.jpg');
      expect(updated.createdAt, testDate);
      expect(updated.updatedAt, newDate);
    });

    test('Document equality works correctly', () {
      // Arrange
      final doc1 = Document(
        id: 'same-id',
        title: 'Document',
        imagePath: '/path.jpg',
        thumbnailPath: '/thumb.jpg',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final doc2 = Document(
        id: 'same-id',
        title: 'Document',
        imagePath: '/path.jpg',
        thumbnailPath: '/thumb.jpg',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final doc3 = Document(
        id: 'different-id',
        title: 'Document',
        imagePath: '/path.jpg',
        thumbnailPath: '/thumb.jpg',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(doc1, equals(doc2));
      expect(doc1, isNot(equals(doc3)));
    });
  });
}
