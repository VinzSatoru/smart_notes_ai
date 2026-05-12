import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';

class FetchNotesUseCase implements UseCase<List<Note>, FetchNotesParams> {
  final NotesRepository repository;

  FetchNotesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Note>>> call(FetchNotesParams params) async {
    return await repository.fetchNotes(params.userId, params.categoryId);
  }
}

class FetchNotesParams extends Equatable {
  final String userId;
  final String categoryId;

  const FetchNotesParams({required this.userId, required this.categoryId});

  @override
  List<Object?> get props => [userId, categoryId];
}
