import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';

class ToggleArchiveUseCase {
  final NotesRepository repository;

  ToggleArchiveUseCase(this.repository);

  Future<Either<Failure, void>> call(Note note) async {
    return await repository.toggleArchive(note);
  }
}
