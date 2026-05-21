import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notes_repository.dart';

class AddCategoryUseCase implements UseCase<void, AddCategoryParams> {
  final NotesRepository repository;

  AddCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddCategoryParams params) async {
    return await repository.addCategory(params.userId, params.name);
  }
}

class AddCategoryParams extends Equatable {
  final String userId;
  final String name;

  const AddCategoryParams({required this.userId, required this.name});

  @override
  List<Object?> get props => [userId, name];
}
