import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/notes_repository.dart';
import '../datasources/notes_remote_data_source.dart';

class NotesRepositoryImpl implements NotesRepository {
  final NotesRemoteDataSource remoteDataSource;

  NotesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Category>>> fetchCategories(String userId) async {
    try {
      final categories = await remoteDataSource.fetchCategories(userId);
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure('Gagal memuat kategori: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Note>>> fetchNotes(String userId, String categoryId) async {
    try {
      final notes = await remoteDataSource.fetchNotes(userId, categoryId);
      return Right(notes);
    } catch (e) {
      return Left(ServerFailure('Gagal memuat catatan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNote(String noteId) async {
    try {
      await remoteDataSource.deleteNote(noteId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal menghapus catatan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> togglePin(Note note) async {
    try {
      await remoteDataSource.togglePin(note.id, note.isPinned);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal menyematkan catatan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleFavorite(Note note) async {
    try {
      await remoteDataSource.toggleFavorite(note.id, note.isFavorite);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal menandai favorit catatan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleArchive(Note note) async {
    try {
      await remoteDataSource.toggleArchive(note.id, note.isArchived);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal mengarsipkan catatan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> moveToTrash(Note note) async {
    try {
      await remoteDataSource.moveToTrash(note.id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal membuang catatan ke sampah: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> restoreNote(Note note) async {
    try {
      await remoteDataSource.restoreNote(note.id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal memulihkan catatan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addNote(String userId, String title, String contentText, String categoryId, {String? aiSummary, String? aiTranslation}) async {
    try {
      await remoteDataSource.addNote(userId, title, contentText, categoryId, aiSummary: aiSummary, aiTranslation: aiTranslation);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal menambahkan catatan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateNote(String noteId, String title, String contentText, String categoryId, {String? aiSummary, String? aiTranslation}) async {
    try {
      await remoteDataSource.updateNote(noteId, title, contentText, categoryId, aiSummary: aiSummary, aiTranslation: aiTranslation);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal memperbarui catatan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addCategory(String userId, String name) async {
    try {
      await remoteDataSource.addCategory(userId, name);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal menambahkan kategori: ${e.toString()}'));
    }
  }
}
