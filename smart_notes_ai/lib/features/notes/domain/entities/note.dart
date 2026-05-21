import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String title;
  final String contentText;
  final bool isPinned;
  final String created;
  final String categoryId;
  final bool isFavorite;
  final bool isArchived;
  final bool isTrashed;
  final String? aiSummary;
  final String? aiTranslation;

  const Note({
    required this.id,
    required this.title,
    required this.contentText,
    required this.isPinned,
    required this.created,
    required this.categoryId,
    this.isFavorite = false,
    this.isArchived = false,
    this.isTrashed = false,
    this.aiSummary,
    this.aiTranslation,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        contentText,
        isPinned,
        created,
        categoryId,
        isFavorite,
        isArchived,
        isTrashed,
        aiSummary,
        aiTranslation,
      ];
}
