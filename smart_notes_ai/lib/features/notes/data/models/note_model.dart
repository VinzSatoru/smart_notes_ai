import 'package:pocketbase/pocketbase.dart';
import '../../domain/entities/note.dart';

class NoteModel extends Note {
  const NoteModel({
    required super.id,
    required super.title,
    required super.contentText,
    required super.isPinned,
    required super.created,
    required super.categoryId,
    super.isFavorite,
    super.isArchived,
    super.isTrashed,
    super.aiSummary,
    super.aiTranslation,
  });

  factory NoteModel.fromRecord(RecordModel record) {
    return NoteModel(
      id: record.id,
      title: record.getStringValue('title'),
      contentText: record.getStringValue('content'),
      isPinned: record.getBoolValue('is_pinned'),
      created: record.getStringValue('created'),
      categoryId: record.getStringValue('category_id'),
      isFavorite: record.getBoolValue('is_favorite'),
      isArchived: record.getBoolValue('is_archived'),
      isTrashed: record.getBoolValue('is_trashed'),
      aiSummary: record.getStringValue('ai_summary'),
      aiTranslation: record.getStringValue('ai_translation'),
    );
  }
}
