class DocumentLoadException implements Exception {
  DocumentLoadException(this.message);

  final String message;

  @override
  String toString() => 'DocumentLoadException: $message';
}

class DocumentSaveException implements Exception {
  DocumentSaveException(this.message);

  final String message;

  @override
  String toString() => 'DocumentSaveException: $message';
}

class DocumentDeleteException implements Exception {
  DocumentDeleteException(this.message);

  final String message;

  @override
  String toString() => 'DocumentDeleteException: $message';
}

class DocumentNotFoundException implements Exception {
  DocumentNotFoundException(this.id);

  final String id;

  String get message => 'Document not found: $id';

  @override
  String toString() => 'DocumentNotFoundException: $message';
}

class ThumbnailGenerationException implements Exception {
  ThumbnailGenerationException(this.message);

  final String message;

  @override
  String toString() => 'ThumbnailGenerationException: $message';
}
