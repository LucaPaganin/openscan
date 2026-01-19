import 'package:flutter/material.dart';

/// Placeholder screen for the Document detail view.
///
/// This will be replaced with actual document viewer in Epic 4.
class DocumentScreen extends StatelessWidget {
  const DocumentScreen({
    super.key,
    required this.documentId,
  });

  /// The ID of the document to display.
  final String documentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Document Detail',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Document ID: $documentId',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(153),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
