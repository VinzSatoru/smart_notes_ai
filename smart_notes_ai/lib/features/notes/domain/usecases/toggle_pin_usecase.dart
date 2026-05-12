import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';

class TogglePinUseCase implements UseCase<void, TogglePinParams> {
  final NotesRepository repository;

  TogglePinUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(TogglePinParams params) async {
    return await repository.togglePin(params.note);
  }
}

class TogglePinParams extends Equatable {
  final Note note;

  const TogglePinParams({required this.note});

  @override
  List<Object?> get props => [note];
}
