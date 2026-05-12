import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase implements UseCase<User, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) async {
    return await repository.register(params.name, params.email, params.password, params.passwordConfirm);
  }
}

class RegisterParams extends Equatable {
  final String name;
  final String email;
  final String password;
  final String passwordConfirm;

  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirm,
  });

  @override
  List<Object?> get props => [name, email, password, passwordConfirm];
}
