import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

import '../../../../core/errors/document_exceptions.dart';
import '../../data/repositories/document_repository.dart';
import '../models/document.dart';

class DocumentService {
  DocumentService(this._repository);

  final DocumentRepository _repository;
  final Uuid _uuid = const Uuid();

  Future<Document> saveCapture(String tempImagePath) async {
    final id = _uuid.v4();
    final timestamp = DateTime.now();
    final title = _generateTitle(timestamp);

    // Get permanent storage paths
    final imagePath = await _repository.getImageStoragePath('$id.jpg');
    final thumbnailPath =
        await _repository.getImageStoragePath('${id}_thumb.jpg');

    // Move image to permanent storage
    final tempFile = File(tempImagePath);
    await tempFile.copy(imagePath);
    await tempFile.delete();

    // Generate thumbnail
    await _generateThumbnail(imagePath, thumbnailPath);

    // Create and save document
    final document = Document(
      id: id,
      title: title,
      imagePath: imagePath,
      thumbnailPath: thumbnailPath,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    return _repository.save(document);
  }

  String _generateTitle(DateTime timestamp) {
    final formatted = '${timestamp.year}-'
        '${timestamp.month.toString().padLeft(2, '0')}-'
        '${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
    return 'Scan $formatted';
  }

  Future<void> _generateThumbnail(String sourcePath, String destPath) async {
    final bytes = await File(sourcePath).readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw ThumbnailGenerationException('Could not decode image');
    }

    final thumbnail = img.copyResize(image, width: 300);
    final thumbBytes = img.encodeJpg(thumbnail, quality: 80);

    await File(destPath).writeAsBytes(thumbBytes);
  }
}
