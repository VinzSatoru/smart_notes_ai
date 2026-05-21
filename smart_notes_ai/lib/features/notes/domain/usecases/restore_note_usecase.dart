import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';

class RestoreNoteUseCase {
  final NotesRepository repository;

  RestoreNoteUseCase(this.repository);

  Future<Either<Failure, void>> call(Note note) async {
    return await repository.restoreNote(note);
  }
}
