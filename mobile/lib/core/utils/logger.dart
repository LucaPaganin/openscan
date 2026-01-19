import 'dart:developer' as developer;

/// Simple logger utility for OpenScan.
///
/// Wraps Dart's developer log with app-specific configuration.
/// In production, this could be extended to integrate with crash reporting.
abstract final class Logger {
  static const String _name = 'OpenScan';

  /// Log a debug message.
  static void debug(String message, {String? tag}) {
    developer.log(
      message,
      name: tag != null ? '$_name.$tag' : _name,
      level: 500, // Fine level
    );
  }

  /// Log an info message.
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag != null ? '$_name.$tag' : _name,
      level: 800, // Info level
    );
  }

  /// Log a warning message.
  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: tag != null ? '$_name.$tag' : _name,
      level: 900, // Warning level
    );
  }

  /// Log an error with optional stack trace.
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag != null ? '$_name.$tag' : _name,
      level: 1000, // Severe level
      error: error,
      stackTrace: stackTrace,
    );
  }
}
