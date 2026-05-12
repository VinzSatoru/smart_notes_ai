import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notes_repository.dart';

class UpdateNoteUseCase implements UseCase<void, UpdateNoteParams> {
  final NotesRepository repository;

  UpdateNoteUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateNoteParams params) async {
    return await repository.updateNote(params.noteId, params.title, params.contentText, params.categoryId);
  }
}

class UpdateNoteParams extends Equatable {
  final String noteId;
  final String title;
  final String contentText;
  final String categoryId;

  const UpdateNoteParams({
    required this.noteId,
    required this.title,
    required this.contentText,
    required this.categoryId,
  });

  @override
  List<Object?> get props => [noteId, title, contentText, categoryId];
}
