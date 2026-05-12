import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/category.dart';
import '../repositories/notes_repository.dart';

class FetchCategoriesUseCase implements UseCase<List<Category>, FetchCategoriesParams> {
  final NotesRepository repository;

  FetchCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(FetchCategoriesParams params) async {
    return await repository.fetchCategories(params.userId);
  }
}

class FetchCategoriesParams extends Equatable {
  final String userId;

  const FetchCategoriesParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
