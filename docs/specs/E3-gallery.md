# Epic 3: Local Gallery

## Epic Overview

**Goal**: Implement local storage and display of captured images. Users can view, browse, and delete their scanned documents. This epic establishes the document management foundation that multi-page scanning (E8) will build upon.

**Duration**: 1 Sprint (1 week)

**Epic Owner**: Luca (Scrum Master)

**Phase**: 1 (Flutter MVP — No Backend Required)

**Dependencies**: E2 (Camera Module) must be complete

---

## Success Criteria

By the end of this epic:
- [ ] Captured images are persisted to local storage
- [ ] Gallery screen displays all saved scans as thumbnails
- [ ] User can tap a thumbnail to view full-size image
- [ ] User can delete individual scans
- [ ] Empty state displays when no scans exist
- [ ] Gallery survives app restart (persistence works)
- [ ] All tests pass with success and failure scenarios

---

## User Stories

### US-3.1: Document Model

**As a** developer  
**I want** a data model representing a scanned document  
**So that** I can store and retrieve document metadata consistently

**Acceptance Criteria**:
- Document model contains: id, title, imagePath, thumbnailPath, createdAt, updatedAt
- Model supports JSON serialization for persistence
- Model is immutable with copyWith support
- ID is generated uniquely (UUID)

**Dependencies**:
```yaml
dependencies:
  uuid: ^4.3.3
  json_annotation: ^4.8.1

dev_dependencies:
  json_serializable: ^6.7.1
```

**Implementation**:
```dart
// lib/features/gallery/domain/models/document.dart

import 'package:json_annotation/json_annotation.dart';

part 'document.g.dart';

@JsonSerializable()
class Document {
  final String id;
  final String title;
  final String imagePath;
  final String? thumbnailPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Document({
    required this.id,
    required this.title,
    required this.imagePath,
    this.thumbnailPath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) => 
      _$DocumentFromJson(json);
  
  Map<String, dynamic> toJson() => _$DocumentToJson(this);

  Document copyWith({
    String? id,
    String? title,
    String? imagePath,
    String? thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

**Tests Required**:
- ✅ Document serializes to JSON correctly
- ✅ Document deserializes from JSON correctly, including null thumbnailPath

---

### US-3.2: Document Repository

**As a** developer  
**I want** a repository to manage document persistence  
**So that** documents are saved and loaded reliably

**Acceptance Criteria**:
- Repository provides: getAll, getById, save, delete operations
- Documents are stored as JSON in a local file
- Image files are stored in app documents directory
- Repository handles concurrent access safely
- Failed operations throw typed exceptions

**Implementation**:
```dart
// lib/features/gallery/data/repositories/document_repository.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
```

**Exception Classes** (`lib/core/errors/document_exceptions.dart`):
```dart
class DocumentLoadException implements Exception {
  final String message;
  DocumentLoadException(this.message);
}

class DocumentSaveException implements Exception {
  final String message;
  DocumentSaveException(this.message);
}

class DocumentDeleteException implements Exception {
  final String message;
  DocumentDeleteException(this.message);
}

class DocumentNotFoundException implements Exception {
  final String id;
  DocumentNotFoundException(this.id);
  
  String get message => 'Document not found: $id';
}
```

**Tests Required**:
- ✅ `save()` persists document and can be retrieved with `getAll()`
- ✅ `delete()` removes document and associated image files

---

### US-3.3: Save Captured Image

**As a** user  
**I want** my captured image to be saved automatically  
**So that** I don't lose my scanned documents

**Acceptance Criteria**:
- After capture, image is moved from temp to permanent storage
- Thumbnail is generated (300px width, maintain aspect ratio)
- Document entry is created with auto-generated title ("Scan YYYY-MM-DD HH:MM")
- User sees confirmation that scan was saved
- Navigation to gallery is offered after save

**Dependencies**:
```yaml
dependencies:
  image: ^4.1.7
```

**Implementation**:
```dart
// lib/features/gallery/domain/services/document_service.dart

import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

class DocumentService {
  final DocumentRepository _repository;
  final Uuid _uuid = const Uuid();
  
  DocumentService(this._repository);
  
  Future<Document> saveCapture(String tempImagePath) async {
    final id = _uuid.v4();
    final timestamp = DateTime.now();
    final title = _generateTitle(timestamp);
    
    // Get permanent storage paths
    final imagePath = await _repository.getImageStoragePath('$id.jpg');
    final thumbnailPath = await _repository.getImageStoragePath('${id}_thumb.jpg');
    
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

// lib/core/errors/document_exceptions.dart (add to existing)

class ThumbnailGenerationException implements Exception {
  final String message;
  ThumbnailGenerationException(this.message);
}
```

**Tests Required**:
- ✅ `saveCapture()` creates document with correct title format
- ✅ `saveCapture()` throws ThumbnailGenerationException for invalid image

---

### US-3.4: Gallery Screen

**As a** user  
**I want** to see all my scanned documents in a gallery  
**So that** I can browse and find my documents easily

**Acceptance Criteria**:
- Gallery displays as a grid (2 columns on phone, 3+ on tablet)
- Each item shows thumbnail with title below
- Documents are sorted by createdAt descending (newest first)
- Pull-to-refresh reloads the gallery
- Loading state shown while fetching documents

**UI Specifications**:
```
┌─────────────────────────────────────────┐
│  Gallery                          [...] │  ← App bar with options
├─────────────────────────────────────────┤
│ ┌─────────┐  ┌─────────┐               │
│ │         │  │         │               │
│ │  Thumb  │  │  Thumb  │               │
│ │         │  │         │               │
│ ├─────────┤  ├─────────┤               │
│ │ Title   │  │ Title   │               │
│ │ Date    │  │ Date    │               │
│ └─────────┘  └─────────┘               │
│                                         │
│ ┌─────────┐  ┌─────────┐               │
│ │         │  │         │               │
│ │  Thumb  │  │  Thumb  │               │
│ ...                                     │
└─────────────────────────────────────────┘

Grid spacing: 8dp
Thumbnail aspect ratio: 3:4 (portrait document)
Title: 14sp, max 2 lines, ellipsis
Date: 12sp, secondary color
```

**Implementation**:
```dart
// lib/features/gallery/presentation/screens/gallery_screen.dart

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(documentsProvider),
        ),
        data: (documents) {
          if (documents.isEmpty) {
            return const _EmptyGalleryView();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(documentsProvider),
            child: _DocumentGrid(documents: documents),
          );
        },
      ),
    );
  }
}

class _DocumentGrid extends StatelessWidget {
  final List<Document> documents;
  
  const _DocumentGrid({required this.documents});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        return DocumentTile(document: documents[index]);
      },
    );
  }
}
```

**Provider**:
```dart
// lib/features/gallery/presentation/providers/documents_provider.dart

@riverpod
Future<List<Document>> documents(DocumentsRef ref) async {
  final repository = ref.watch(documentRepositoryProvider);
  final documents = await repository.getAll();
  // Sort by newest first
  documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return documents;
}

@riverpod
DocumentRepository documentRepository(DocumentRepositoryRef ref) {
  return DocumentRepository();
}
```

**Tests Required**:
- ✅ Gallery displays documents sorted by createdAt descending
- ✅ Gallery shows empty state when no documents exist

---

### US-3.5: Document Tile

**As a** user  
**I want** to see a preview of each document  
**So that** I can identify documents quickly

**Acceptance Criteria**:
- Tile displays thumbnail image
- Tile shows document title (truncated if too long)
- Tile shows creation date in friendly format ("Today", "Yesterday", "Jan 15")
- Tapping tile navigates to document detail view
- Long-press shows context menu (delete option)

**Implementation**:
```dart
// lib/features/gallery/presentation/widgets/document_tile.dart

class DocumentTile extends StatelessWidget {
  final Document document;
  
  const DocumentTile({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDocument(context),
      onLongPress: () => _showContextMenu(context),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _ThumbnailImage(path: document.thumbnailPath),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(document.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _openDocument(BuildContext context) {
    context.push('/document/${document.id}');
  }
  
  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DocumentContextMenu(document: document),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${_monthName(date.month)} ${date.day}';
    }
  }
  
  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _ThumbnailImage extends StatelessWidget {
  final String? path;
  
  const _ThumbnailImage({this.path});

  @override
  Widget build(BuildContext context) {
    if (path == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: const Icon(Icons.image_not_supported),
      );
    }
    
    return Image.file(
      File(path!),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: const Icon(Icons.broken_image),
      ),
    );
  }
}
```

**Tests Required**:
- ✅ Document tile displays title and formatted date
- ✅ Document tile shows placeholder when thumbnail path is null

---

### US-3.6: Empty Gallery State

**As a** user  
**I want** to see a helpful message when I have no scans  
**So that** I know how to get started

**Acceptance Criteria**:
- Centered illustration or icon
- Friendly message: "No scans yet"
- Sub-message: "Tap the camera to scan your first document"
- Optional: Button to navigate to camera

**Implementation**:
```dart
// lib/features/gallery/presentation/widgets/empty_gallery_view.dart

class EmptyGalleryView extends StatelessWidget {
  const EmptyGalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No scans yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the camera to scan your first document',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Start Scanning'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Tests Required**:
- ✅ Empty view displays correct message text
- ✅ Empty view button navigates to camera screen

---

### US-3.7: Document Detail View

**As a** user  
**I want** to view a full-size image of my scan  
**So that** I can review the document details

**Acceptance Criteria**:
- Full-screen image view with zoom/pan support
- App bar shows document title
- Back button returns to gallery
- Share button (prepares for future sharing feature)
- Delete button with confirmation

**Dependencies**:
```yaml
dependencies:
  photo_view: ^0.14.0
```

**Implementation**:
```dart
// lib/features/document/presentation/screens/document_detail_screen.dart

class DocumentDetailScreen extends ConsumerWidget {
  final String documentId;
  
  const DocumentDetailScreen({super.key, required this.documentId});

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
  final Document document;
  
  const _DocumentDetailView({required this.document});

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
    // Placeholder for future share implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share coming soon')),
    );
  }
  
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this scan? This action cannot be undone.'),
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
    
    if (confirmed == true && context.mounted) {
      await ref.read(documentRepositoryProvider).delete(document.id);
      ref.invalidate(documentsProvider);
      if (context.mounted) {
        context.pop();
      }
    }
  }
}

// Provider
@riverpod
Future<Document?> documentById(DocumentByIdRef ref, String id) async {
  final repository = ref.watch(documentRepositoryProvider);
  return repository.getById(id);
}
```

**Tests Required**:
- ✅ Document detail displays image when document exists
- ✅ Document detail shows "not found" when document doesn't exist

---

### US-3.8: Delete Document

**As a** user  
**I want** to delete unwanted scans  
**So that** I can manage my storage

**Acceptance Criteria**:
- Delete available from document detail view (app bar)
- Delete available from long-press context menu in gallery
- Confirmation dialog before deletion
- After deletion, user returns to gallery
- Gallery refreshes to reflect deletion
- Undo option in snackbar (optional, nice-to-have)

**Implementation**:
```dart
// lib/features/gallery/presentation/widgets/document_context_menu.dart

class DocumentContextMenu extends ConsumerWidget {
  final Document document;
  
  const DocumentContextMenu({super.key, required this.document});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open'),
            onTap: () {
              Navigator.pop(context);
              context.push('/document/${document.id}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(context, ref);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context, ref);
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: document.title);
    
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (newTitle != null && newTitle.isNotEmpty && newTitle != document.title) {
      final updated = document.copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );
      await ref.read(documentRepositoryProvider).save(updated);
      ref.invalidate(documentsProvider);
    }
  }
  
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${document.title}"? This cannot be undone.'),
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
    
    if (confirmed == true) {
      await ref.read(documentRepositoryProvider).delete(document.id);
      ref.invalidate(documentsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
    }
  }
}
```

**Tests Required**:
- ✅ Delete removes document from repository and refreshes gallery
- ✅ Delete cancellation does not remove document

---

## Integration with Camera (E2)

After capture, connect to document service:

```dart
// Update in camera screen after successful capture

Future<void> _onCaptureComplete(CapturedImage image) async {
  final documentService = ref.read(documentServiceProvider);
  
  try {
    final document = await documentService.saveCapture(image.path);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Scan saved'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => context.push('/document/${document.id}'),
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }
}
```

---

## State Management

### Providers Structure

```
lib/features/gallery/
├── presentation/
│   └── providers/
│       ├── documents_provider.dart      # All documents list
│       └── document_by_id_provider.dart # Single document lookup
├── domain/
│   ├── models/
│   │   └── document.dart
│   └── services/
│       └── document_service.dart
└── data/
    └── repositories/
        └── document_repository.dart
```

---

## File Storage Structure

```
{app_documents_dir}/
└── scans/
    ├── documents.json           # Metadata for all documents
    ├── {uuid}.jpg               # Full-size images
    └── {uuid}_thumb.jpg         # Thumbnails (300px width)
```

---

## Definition of Done

- [ ] Document model with JSON serialization works
- [ ] Repository saves and loads documents correctly
- [ ] Captured images are persisted with thumbnails
- [ ] Gallery displays all documents as grid
- [ ] Empty state shows when no documents
- [ ] Tapping document opens detail view
- [ ] Delete works from both gallery and detail view
- [ ] Rename works from context menu
- [ ] Pull-to-refresh reloads gallery
- [ ] All tests pass (minimum 2 scenarios per component)
- [ ] No lint warnings
- [ ] Code committed with conventional commit messages

---

## Out of Scope

The following are explicitly NOT part of this epic:
- Multi-page documents (Epic 8)
- PDF export (Epic 8)
- Image editing/filters (Epic 7)
- Cloud sync/backup
- Search functionality
- Folders/tags organization

---

## Implementation Order

Suggested order for Claude Code:

1. Add dependencies (`uuid`, `json_annotation`, `json_serializable`, `image`, `photo_view`)
2. Create Document model with JSON serialization
3. Run `build_runner` to generate serialization code
4. Create document exception classes
5. Implement DocumentRepository
6. Implement DocumentService with thumbnail generation
7. Create documents provider
8. Create document tile widget
9. Create empty gallery view widget
10. Create gallery screen with grid
11. Create document context menu
12. Create document detail screen
13. Create document_by_id provider
14. Update routes in app_router.dart
15. Connect camera capture to document service
16. Write tests for all components
17. Run `flutter analyze` and fix any issues

---

## Notes for Claude Code

When implementing this epic:

1. **Run build_runner** after creating models: `dart run build_runner build --delete-conflicting-outputs`
2. **Test persistence** — restart app and verify documents reload
3. **Test thumbnail generation** — verify images are properly resized
4. **Handle file paths** — use path_provider, never hardcode paths
5. **Memory management** — dispose image resources properly
6. **Follow CLAUDE.md** — especially the two-scenario testing requirement

---

## Confirmed Decisions

- **Storage format**: JSON file for metadata, separate image files
- **Thumbnail size**: 300px width, maintain aspect ratio
- **Grid columns**: 2 on phone (fixed for now, responsive later)
- **Sort order**: Newest first
- **Title format**: "Scan YYYY-MM-DD HH:MM"