import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../core/errors/exceptions.dart';

/// Service for managing local file storage.
///
/// Provides operations for saving, loading, deleting, and listing files
/// in the app's documents directory. All scanned documents are stored
/// in a 'scans' subdirectory.
class StorageService {
  /// Creates a new storage service instance.
  const StorageService();

  /// The name of the subdirectory where scans are stored.
  static const String _scansDirectoryName = 'scans';

  /// Gets the scans directory, creating it if it doesn't exist.
  ///
  /// Returns a [Directory] pointing to the scans folder.
  /// Throws [StorageException] if the directory cannot be accessed or created.
  Future<Directory> get scansDirectory async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final scansDir = Directory('${appDir.path}/$_scansDirectoryName');

      if (!await scansDir.exists()) {
        await scansDir.create(recursive: true);
      }

      return scansDir;
    } on FileSystemException catch (e) {
      throw StorageException(
        message: 'Failed to create scans directory: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      throw StorageException(
        message: 'Failed to access application documents directory: $e',
        originalError: e,
      );
    }
  }

  /// Saves bytes to a file with the given filename.
  ///
  /// If a file with the same name exists, it will be overwritten.
  /// Returns the saved [File].
  ///
  /// Throws [StorageException] if the file cannot be saved.
  Future<File> saveFile(String filename, List<int> bytes) async {
    if (filename.isEmpty) {
      throw const StorageException(
        message: 'Filename cannot be empty',
        userMessage: 'Invalid filename provided.',
      );
    }

    try {
      final dir = await scansDirectory;
      final file = File('${dir.path}/$filename');
      return await file.writeAsBytes(bytes, flush: true);
    } on FileSystemException catch (e) {
      throw StorageException(
        message: 'Failed to save file "$filename": ${e.message}',
        userMessage: 'Could not save the file. Please try again.',
        originalError: e,
      );
    }
  }

  /// Loads the contents of a file with the given filename.
  ///
  /// Returns the file contents as a [Uint8List].
  ///
  /// Throws [FileException] if the file does not exist or cannot be read.
  Future<Uint8List> loadFile(String filename) async {
    if (filename.isEmpty) {
      throw const FileException(
        message: 'Filename cannot be empty',
        userMessage: 'Invalid filename provided.',
      );
    }

    try {
      final dir = await scansDirectory;
      final file = File('${dir.path}/$filename');

      if (!await file.exists()) {
        throw FileException(
          message: 'File "$filename" not found',
          userMessage: 'The requested file could not be found.',
        );
      }

      return await file.readAsBytes();
    } on FileException {
      rethrow;
    } on StorageException {
      rethrow;
    } on FileSystemException catch (e) {
      throw FileException(
        message: 'Failed to read file "$filename": ${e.message}',
        userMessage: 'Could not read the file. Please try again.',
        originalError: e,
      );
    }
  }

  /// Deletes a file with the given filename.
  ///
  /// Does nothing if the file doesn't exist (idempotent operation).
  ///
  /// Throws [FileException] if the file exists but cannot be deleted.
  Future<void> deleteFile(String filename) async {
    if (filename.isEmpty) {
      throw const FileException(
        message: 'Filename cannot be empty',
        userMessage: 'Invalid filename provided.',
      );
    }

    try {
      final dir = await scansDirectory;
      final file = File('${dir.path}/$filename');

      if (await file.exists()) {
        await file.delete();
      }
      // If file doesn't exist, we consider the delete successful (idempotent)
    } on StorageException {
      rethrow;
    } on FileSystemException catch (e) {
      throw FileException(
        message: 'Failed to delete file "$filename": ${e.message}',
        userMessage: 'Could not delete the file. Please try again.',
        originalError: e,
      );
    }
  }

  /// Lists all files in the scans directory.
  ///
  /// Returns a list of [FileSystemEntity] objects representing the files.
  /// Returns an empty list if the directory is empty.
  ///
  /// Throws [StorageException] if the directory cannot be accessed.
  Future<List<FileSystemEntity>> listFiles() async {
    try {
      final dir = await scansDirectory;
      return dir.listSync().whereType<File>().toList();
    } on StorageException {
      rethrow;
    } on FileSystemException catch (e) {
      throw StorageException(
        message: 'Failed to list files: ${e.message}',
        userMessage: 'Could not list files. Please try again.',
        originalError: e,
      );
    }
  }

  /// Checks if a file with the given filename exists.
  ///
  /// Returns `true` if the file exists, `false` otherwise.
  ///
  /// Throws [StorageException] if the directory cannot be accessed.
  Future<bool> fileExists(String filename) async {
    if (filename.isEmpty) {
      return false;
    }

    try {
      final dir = await scansDirectory;
      final file = File('${dir.path}/$filename');
      return file.exists();
    } on StorageException {
      rethrow;
    } on FileSystemException catch (e) {
      throw StorageException(
        message: 'Failed to check if file exists: ${e.message}',
        originalError: e,
      );
    }
  }

  /// Gets the full path for a file with the given filename.
  ///
  /// Returns the absolute path to where the file is or would be stored.
  ///
  /// Throws [StorageException] if the directory cannot be accessed.
  Future<String> getFilePath(String filename) async {
    final dir = await scansDirectory;
    return '${dir.path}/$filename';
  }

  /// Clears all files in the scans directory.
  ///
  /// Use with caution - this operation is irreversible.
  ///
  /// Throws [StorageException] if the files cannot be deleted.
  Future<void> clearAll() async {
    try {
      final files = await listFiles();
      for (final file in files) {
        await file.delete();
      }
    } on StorageException {
      rethrow;
    } on FileSystemException catch (e) {
      throw StorageException(
        message: 'Failed to clear all files: ${e.message}',
        userMessage: 'Could not clear files. Please try again.',
        originalError: e,
      );
    }
  }
}
