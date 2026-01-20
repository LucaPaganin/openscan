/// Represents an image captured by the camera.
///
/// Contains the file path to the captured image and metadata
/// about when it was captured.
class CapturedImage {
  const CapturedImage({
    required this.path,
    required this.timestamp,
  });

  /// The file path to the captured image in temporary storage.
  final String path;

  /// The timestamp when the image was captured.
  final DateTime timestamp;

  @override
  String toString() => 'CapturedImage(path: $path, timestamp: $timestamp)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CapturedImage &&
        other.path == path &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(path, timestamp);
}
