import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openscan/core/errors/exceptions.dart';
import 'package:openscan/shared/services/storage_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Mock implementation of PathProviderPlatform for testing.
class MockPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  MockPathProvider(this.testDirectory);

  final Directory testDirectory;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return testDirectory.path;
  }
}

void main() {
  late StorageService storageService;
  late Directory testDirectory;

  setUp(() async {
    // Create a temporary directory for testing
    testDirectory = await Directory.systemTemp.createTemp('openscan_test_');

    // Set up the mock path provider
    PathProviderPlatform.instance = MockPathProvider(testDirectory);

    storageService = const StorageService();
  });

  tearDown(() async {
    // Clean up the test directory
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  group('StorageService', () {
    group('saveFile', () {
      test('creates file in correct directory when given valid data', () async {
        // Arrange
        const filename = 'test_document.png';
        final bytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);

        // Act
        final file = await storageService.saveFile(filename, bytes);

        // Assert
        expect(await file.exists(), isTrue);
        expect(file.path.contains('scans'), isTrue);
        expect(file.path.endsWith(filename), isTrue);

        final savedBytes = await file.readAsBytes();
        expect(savedBytes, equals(bytes));
      });

      test('overwrites existing file when saving with same filename', () async {
        // Arrange
        const filename = 'overwrite_test.png';
        final originalBytes = Uint8List.fromList([1, 2, 3]);
        final newBytes = Uint8List.fromList([4, 5, 6, 7, 8]);

        // Act
        await storageService.saveFile(filename, originalBytes);
        final file = await storageService.saveFile(filename, newBytes);

        // Assert
        final savedBytes = await file.readAsBytes();
        expect(savedBytes, equals(newBytes));
        expect(savedBytes.length, equals(5));
      });

      test('throws StorageException when filename is empty', () async {
        // Arrange
        final bytes = Uint8List.fromList([1, 2, 3]);

        // Act & Assert
        expect(
          () => storageService.saveFile('', bytes),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('loadFile', () {
      test('returns file contents when file exists', () async {
        // Arrange
        const filename = 'load_test.png';
        final expectedBytes = Uint8List.fromList([10, 20, 30, 40, 50]);
        await storageService.saveFile(filename, expectedBytes);

        // Act
        final loadedBytes = await storageService.loadFile(filename);

        // Assert
        expect(loadedBytes, equals(expectedBytes));
      });

      test('throws FileException when file does not exist', () async {
        // Arrange
        const filename = 'nonexistent_file.png';

        // Act & Assert
        expect(
          () => storageService.loadFile(filename),
          throwsA(isA<FileException>()),
        );
      });

      test('throws FileException when filename is empty', () async {
        // Act & Assert
        expect(
          () => storageService.loadFile(''),
          throwsA(isA<FileException>()),
        );
      });
    });

    group('deleteFile', () {
      test('removes file when it exists', () async {
        // Arrange
        const filename = 'delete_test.png';
        final bytes = Uint8List.fromList([1, 2, 3]);
        await storageService.saveFile(filename, bytes);

        // Verify file exists
        expect(await storageService.fileExists(filename), isTrue);

        // Act
        await storageService.deleteFile(filename);

        // Assert
        expect(await storageService.fileExists(filename), isFalse);
      });

      test('handles non-existent file gracefully (idempotent)', () async {
        // Arrange
        const filename = 'already_deleted.png';

        // Act & Assert - should not throw
        await expectLater(
          storageService.deleteFile(filename),
          completes,
        );
      });

      test('throws FileException when filename is empty', () async {
        // Act & Assert
        expect(
          () => storageService.deleteFile(''),
          throwsA(isA<FileException>()),
        );
      });
    });

    group('listFiles', () {
      test('returns list of saved files', () async {
        // Arrange
        final files = ['file1.png', 'file2.png', 'file3.png'];
        final bytes = Uint8List.fromList([1, 2, 3]);

        for (final filename in files) {
          await storageService.saveFile(filename, bytes);
        }

        // Act
        final listedFiles = await storageService.listFiles();

        // Assert
        expect(listedFiles.length, equals(3));
        final listedNames = listedFiles.map((f) => f.path.split('/').last);
        expect(listedNames, containsAll(files));
      });

      test('returns empty list when no files exist', () async {
        // Act
        final files = await storageService.listFiles();

        // Assert
        expect(files, isEmpty);
      });
    });

    group('fileExists', () {
      test('returns true when file exists', () async {
        // Arrange
        const filename = 'exists_test.png';
        final bytes = Uint8List.fromList([1, 2, 3]);
        await storageService.saveFile(filename, bytes);

        // Act
        final exists = await storageService.fileExists(filename);

        // Assert
        expect(exists, isTrue);
      });

      test('returns false when file does not exist', () async {
        // Act
        final exists = await storageService.fileExists('nonexistent.png');

        // Assert
        expect(exists, isFalse);
      });

      test('returns false when filename is empty', () async {
        // Act
        final exists = await storageService.fileExists('');

        // Assert
        expect(exists, isFalse);
      });
    });

    group('clearAll', () {
      test('removes all files from scans directory', () async {
        // Arrange
        final bytes = Uint8List.fromList([1, 2, 3]);
        await storageService.saveFile('file1.png', bytes);
        await storageService.saveFile('file2.png', bytes);
        await storageService.saveFile('file3.png', bytes);

        // Verify files exist
        var files = await storageService.listFiles();
        expect(files.length, equals(3));

        // Act
        await storageService.clearAll();

        // Assert
        files = await storageService.listFiles();
        expect(files, isEmpty);
      });

      test('handles empty directory gracefully', () async {
        // Act & Assert - should not throw
        await expectLater(
          storageService.clearAll(),
          completes,
        );
      });
    });

    group('getFilePath', () {
      test('returns correct path for filename', () async {
        // Arrange
        const filename = 'path_test.png';

        // Act
        final path = await storageService.getFilePath(filename);

        // Assert
        expect(path.contains('scans'), isTrue);
        expect(path.endsWith(filename), isTrue);
      });
    });
  });
}
