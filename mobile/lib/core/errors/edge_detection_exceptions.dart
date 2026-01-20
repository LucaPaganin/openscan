/// Exception thrown when edge detection fails.
class EdgeDetectionException implements Exception {
  EdgeDetectionException(this.message);

  final String message;

  @override
  String toString() => 'EdgeDetectionException: $message';
}
