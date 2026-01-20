import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/document_repository.dart';
import '../../domain/models/document.dart';
import '../../domain/services/document_service.dart';

part 'documents_provider.g.dart';

@riverpod
DocumentRepository documentRepository(Ref ref) {
  return DocumentRepository();
}

@riverpod
DocumentService documentService(Ref ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return DocumentService(repository);
}

@riverpod
Future<List<Document>> documents(Ref ref) async {
  final repository = ref.watch(documentRepositoryProvider);
  final documents = await repository.getAll();
  // Sort by newest first
  documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return documents;
}

@riverpod
Future<Document?> documentById(Ref ref, String id) async {
  final repository = ref.watch(documentRepositoryProvider);
  return repository.getById(id);
}
