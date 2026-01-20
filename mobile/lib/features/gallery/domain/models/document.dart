import 'package:json_annotation/json_annotation.dart';

part 'document.g.dart';

@JsonSerializable()
class Document {
  const Document({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
  });

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);

  final String id;
  final String title;
  final String imagePath;
  final String? thumbnailPath;
  final DateTime createdAt;
  final DateTime updatedAt;

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Document &&
        other.id == id &&
        other.title == title &&
        other.imagePath == imagePath &&
        other.thumbnailPath == thumbnailPath &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      imagePath,
      thumbnailPath,
      createdAt,
      updatedAt,
    );
  }
}
