import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notes_repository.dart';

class DeleteNoteUseCase implements UseCase<void, DeleteNoteParams> {
  final NotesRepository repository;

  DeleteNoteUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteNoteParams params) async {
    return await repository.deleteNote(params.noteId);
  }
}

class DeleteNoteParams extends Equatable {
  final String noteId;

  const DeleteNoteParams({required this.noteId});

  @override
  List<Object?> get props => [noteId];
}
