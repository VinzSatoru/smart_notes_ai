import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/note.dart';
import '../entities/category.dart';

abstract class NotesRepository {
  Future<Either<Failure, List<Category>>> fetchCategories(String userId);
  Future<Either<Failure, List<Note>>> fetchNotes(String userId, String categoryId);
  Future<Either<Failure, void>> deleteNote(String noteId);
  Future<Either<Failure, void>> togglePin(Note note);
  Future<Either<Failure, void>> addNote(String userId, String title, String contentText, String categoryId, {String? aiSummary, String? aiTranslation});
  Future<Either<Failure, void>> updateNote(String noteId, String title, String contentText, String categoryId, {String? aiSummary, String? aiTranslation});
  Future<Either<Failure, void>> addCategory(String userId, String name);
}
