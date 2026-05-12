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
  });

  factory NoteModel.fromRecord(RecordModel record) {
    return NoteModel(
      id: record.id,
      title: record.getStringValue('title'),
      contentText: record.getStringValue('content'),
      isPinned: record.getBoolValue('is_pinned'),
      created: record.getStringValue('created'),
      categoryId: record.getStringValue('category_id'),
    );
  }
}
