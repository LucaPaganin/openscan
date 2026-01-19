/// Base exception class for OpenScan.
///
/// All custom exceptions should extend this class to ensure consistent
/// error handling and user-friendly messaging.
abstract class AppException implements Exception {
  const AppException({
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
  });

  /// Technical error message for logging.
  final String message;

  /// User-friendly error message to display in UI.
  /// Falls back to [message] if not provided.
  final String? userMessage;

  /// The original error that caused this exception.
  final Object? originalError;

  /// Stack trace at the point of error.
  final StackTrace? stackTrace;

  /// Returns the user-facing message.
  String get displayMessage => userMessage ?? message;

  @override
  String toString() => 'AppException: $message';
}

/// Exception thrown when storage operations fail.
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.userMessage = 'Unable to access storage. Please try again.',
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'StorageException: $message';
}

/// Exception thrown when file operations fail.
class FileException extends AppException {
  const FileException({
    required super.message,
    super.userMessage = 'File operation failed. Please try again.',
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'FileException: $message';
}

/// Exception thrown when image processing fails.
class ImageProcessingException extends AppException {
  const ImageProcessingException({
    required super.message,
    super.userMessage = 'Unable to process image. Please try a different image.',
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'ImageProcessingException: $message';
}

/// Exception thrown when camera operations fail.
class CameraException extends AppException {
  const CameraException({
    required super.message,
    super.userMessage = 'Camera is unavailable. Please check permissions.',
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'CameraException: $message';
}

/// Exception thrown when document is not found.
class DocumentNotFoundException extends AppException {
  const DocumentNotFoundException({
    required super.message,
    super.userMessage = 'Document not found.',
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'DocumentNotFoundException: $message';
}
