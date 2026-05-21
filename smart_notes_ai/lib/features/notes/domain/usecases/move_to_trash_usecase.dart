import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';

class MoveToTrashUseCase {
  final NotesRepository repository;

  MoveToTrashUseCase(this.repository);

  Future<Either<Failure, void>> call(Note note) async {
    return await repository.moveToTrash(note);
  }
}
