import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/errors/document_exceptions.dart';
import '../../domain/models/document.dart';

class DocumentRepository {
  static const _documentsFileName = 'documents.json';

  Future<Directory> get _documentsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/scans');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> get _metadataFile async {
    final dir = await _documentsDir;
    return File('${dir.path}/$_documentsFileName');
  }

  Future<List<Document>> getAll() async {
    try {
      final file = await _metadataFile;
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      if (content.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((j) => Document.fromJson(j)).toList();
    } catch (e) {
      throw DocumentLoadException('Failed to load documents: $e');
    }
  }

  Future<Document?> getById(String id) async {
    final documents = await getAll();
    try {
      return documents.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Document> save(Document document) async {
    try {
      final documents = await getAll();
      final existingIndex = documents.indexWhere((d) => d.id == document.id);

      if (existingIndex >= 0) {
        documents[existingIndex] = document;
      } else {
        documents.add(document);
      }

      await _saveAll(documents);
      return document;
    } catch (e) {
      throw DocumentSaveException('Failed to save document: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final documents = await getAll();
      final document = documents.firstWhere(
        (d) => d.id == id,
        orElse: () => throw DocumentNotFoundException(id),
      );

      // Delete image files
      final imageFile = File(document.imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      if (document.thumbnailPath != null) {
        final thumbFile = File(document.thumbnailPath!);
        if (await thumbFile.exists()) {
          await thumbFile.delete();
        }
      }

      // Remove from list and save
      documents.removeWhere((d) => d.id == id);
      await _saveAll(documents);
    } catch (e) {
      if (e is DocumentNotFoundException) rethrow;
      throw DocumentDeleteException('Failed to delete document: $e');
    }
  }

  Future<void> _saveAll(List<Document> documents) async {
    final file = await _metadataFile;
    final jsonList = documents.map((d) => d.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }

  Future<String> getImageStoragePath(String filename) async {
    final dir = await _documentsDir;
    return '${dir.path}/$filename';
  }
}
