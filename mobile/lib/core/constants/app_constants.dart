/// Application-wide constants for OpenScan.
///
/// Contains configuration values, magic numbers, and string constants
/// used throughout the application.
library;

/// App metadata constants.
abstract final class AppConstants {
  /// The display name of the application.
  static const String appName = 'OpenScan';

  /// The app identifier used for package naming.
  static const String appId = 'com.lucaplawliet.openscan';

  /// Current app version (should match pubspec.yaml).
  static const String version = '1.0.0';

  /// Directory name for storing scanned documents.
  static const String scansDirectoryName = 'scans';

  /// Supported image file extensions.
  static const List<String> supportedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'heic',
  ];

  /// Maximum file size for images in bytes (20MB).
  static const int maxImageSizeBytes = 20 * 1024 * 1024;
}
