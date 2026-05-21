import '../../../../services/pocketbase_service.dart';
import '../models/note_model.dart';
import '../models/category_model.dart';

abstract class NotesRemoteDataSource {
  Future<List<CategoryModel>> fetchCategories(String userId);
  Future<List<NoteModel>> fetchNotes(String userId, String categoryId);
  Future<void> deleteNote(String noteId);
  Future<void> togglePin(String noteId, bool currentPinStatus);
  Future<void> addNote(String userId, String title, String contentText, String categoryId, {String? aiSummary, String? aiTranslation});
  Future<void> updateNote(String noteId, String title, String contentText, String categoryId, {String? aiSummary, String? aiTranslation});
  Future<void> addCategory(String userId, String name);
}

class NotesRemoteDataSourceImpl implements NotesRemoteDataSource {
  final PocketBaseService pbService;

  NotesRemoteDataSourceImpl({required this.pbService});

  @override
  Future<List<CategoryModel>> fetchCategories(String userId) async {
    final records = await pbService.pb.collection('categories').getFullList(
      filter: 'user_id = "$userId"',
      sort: 'created', // Diurutkan berdasarkan pembuatan, yang terlama (base) di atas
    );
    return records.map((record) => CategoryModel.fromRecord(record)).toList();
  }

  @override
  Future<void> addCategory(String userId, String name) async {
    await pbService.pb.collection('categories').create(body: {
      "user_id": userId,
      "name": name,
    });
  }

  @override
  Future<List<NoteModel>> fetchNotes(String userId, String categoryId) async {
    String filterStr = 'user_id = "$userId"';
    
    if (categoryId != 'all') {
      filterStr += ' && category_id = "$categoryId"';
    }

    final records = await pbService.pb.collection('notes').getFullList(
      filter: filterStr,
      sort: '-is_pinned,-created',
    );
    
    return records.map((record) => NoteModel.fromRecord(record)).toList();
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await pbService.pb.collection('notes').delete(noteId);
  }

  @override
  Future<void> togglePin(String noteId, bool currentPinStatus) async {
    await pbService.pb.collection('notes').update(noteId, body: {
      'is_pinned': !currentPinStatus,
    });
  }

  @override
  Future<void> addNote(String userId, String title, String contentText, String categoryId, {String? aiSummary, String? aiTranslation}) async {
    final body = <String, dynamic>{
      "user_id": userId,
      "title": title,
      "content": contentText,
      "is_pinned": false,
    };
    if (aiSummary != null) body['ai_summary'] = aiSummary;
    if (aiTranslation != null) body['ai_translation'] = aiTranslation;
    if (categoryId != 'all' && categoryId.isNotEmpty) {
      body["category_id"] = categoryId;
    }
    await pbService.pb.collection('notes').create(body: body);
  }

  @override
  Future<void> updateNote(String noteId, String title, String contentText, String categoryId, {String? aiSummary, String? aiTranslation}) async {
    final body = <String, dynamic>{
      "title": title,
      "content": contentText,
    };
    if (aiSummary != null) body['ai_summary'] = aiSummary;
    if (aiTranslation != null) body['ai_translation'] = aiTranslation;
    if (categoryId != 'all' && categoryId.isNotEmpty) {
      body["category_id"] = categoryId;
    } else {
      body["category_id"] = ""; // Remove category
    }
    await pbService.pb.collection('notes').update(noteId, body: body);
  }
}
