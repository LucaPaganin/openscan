import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import '../../../gallery/domain/models/document.dart';
import '../../../gallery/presentation/providers/documents_provider.dart';

class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentByIdProvider(documentId));

    return documentAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
      data: (document) {
        if (document == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Document not found')),
          );
        }
        return _DocumentDetailView(document: document);
      },
    );
  }
}

class _DocumentDetailView extends ConsumerWidget {
  const _DocumentDetailView({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _share(context),
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: FileImage(File(document.imagePath)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        backgroundDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  void _share(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share coming soon')),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
            'Are you sure you want to delete this scan? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      await ref.read(documentRepositoryProvider).delete(document.id);
      ref.invalidate(documentsProvider);
      if (context.mounted) {
        context.pop();
      }
    }
  }
}
