import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notes_repository.dart';

class AddNoteUseCase implements UseCase<void, AddNoteParams> {
  final NotesRepository repository;

  AddNoteUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddNoteParams params) async {
    return await repository.addNote(
      params.userId, 
      params.title, 
      params.contentText, 
      params.categoryId,
      aiSummary: params.aiSummary,
      aiTranslation: params.aiTranslation,
    );
  }
}

class AddNoteParams extends Equatable {
  final String userId;
  final String title;
  final String contentText;
  final String categoryId;
  final String? aiSummary;
  final String? aiTranslation;

  const AddNoteParams({
    required this.userId,
    required this.title,
    required this.contentText,
    required this.categoryId,
    this.aiSummary,
    this.aiTranslation,
  });

  @override
  List<Object?> get props => [userId, title, contentText, categoryId, aiSummary, aiTranslation];
}
