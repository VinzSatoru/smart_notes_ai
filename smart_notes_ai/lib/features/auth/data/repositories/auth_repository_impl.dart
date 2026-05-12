import 'package:dartz/dartz.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final record = await remoteDataSource.login(email, password);
      return Right(_mapRecordToUser(record));
    } on ClientException catch (e) {
      return Left(ServerFailure(e.response['message'] ?? 'Login gagal. Periksa email dan password Anda.'));
    } catch (e) {
      return const Left(ServerFailure('Terjadi kesalahan tidak terduga.'));
    }
  }

  @override
  Future<Either<Failure, User>> register(String name, String email, String password, String passwordConfirm) async {
    try {
      // 1. Create account
      await remoteDataSource.register(name, email, password, passwordConfirm);
      
      // 2. Login immediately after register
      final record = await remoteDataSource.login(email, password);
      return Right(_mapRecordToUser(record));
    } on ClientException catch (e) {
      return Left(ServerFailure(e.response['message'] ?? 'Gagal mendaftar. Pastikan email belum digunakan.'));
    } catch (e) {
      return const Left(ServerFailure('Terjadi kesalahan tidak terduga.'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      return const Left(ServerFailure('Gagal melakukan logout.'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final record = await remoteDataSource.getCurrentUser();
      if (record != null) {
        return Right(_mapRecordToUser(record));
      } else {
        return const Left(ServerFailure('Tidak ada user yang sedang login.'));
      }
    } catch (e) {
      return const Left(ServerFailure('Terjadi kesalahan tidak terduga.'));
    }
  }

  User _mapRecordToUser(RecordModel record) {
    return User(
      id: record.id,
      email: record.getStringValue('email'),
      name: record.getStringValue('name'),
    );
  }
}
