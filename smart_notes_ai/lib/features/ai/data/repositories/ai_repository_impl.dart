import 'package:dartz/dartz.dart';
import 'package:smart_notes_ai/features/ai/domain/entities/usage_status.dart';
import 'package:smart_notes_ai/features/ai/domain/repositories/ai_repository.dart';
import 'package:smart_notes_ai/features/ai/data/datasources/ai_remote_data_source.dart';
import 'package:smart_notes_ai/services/pocketbase_service.dart';

class AiRepositoryImpl implements AiRepository {
  final AiRemoteDataSource remoteDataSource;
  final PocketBaseService pbService;

  AiRepositoryImpl({
    required this.remoteDataSource,
    required this.pbService,
  });

  @override
  Future<Either<String, UsageStatus>> checkUsageQuota() async {
    try {
      final user = pbService.currentUser;
      if (user == null) {
        return const Left('Sesi telah berakhir, silakan login kembali.');
      }

      final tier = user.getStringValue('tier');
      if (tier == 'pro') {
        return const Right(UsageStatus(
          isAllowed: true,
          remainingQuota: 9999, // Unlimited for pro
          message: 'Pro Tier',
        ));
      }

      // Check free tier limits (Max 3 per day)
      final todayCount = await remoteDataSource.getTodayUsageCount(user.id);
      final maxFreeQuota = 3;
      final remaining = maxFreeQuota - todayCount;

      if (remaining > 0) {
        return Right(UsageStatus(
          isAllowed: true,
          remainingQuota: remaining,
          message: 'Sisa kuota hari ini: $remaining',
        ));
      } else {
        return const Right(UsageStatus(
          isAllowed: false,
          remainingQuota: 0,
          message: 'Kuota AI gratis hari ini telah habis. Silakan upgrade ke Pro.',
        ));
      }
    } catch (e) {
      return Left('Terjadi kesalahan saat mengecek kuota: $e');
    }
  }

  @override
  Future<Either<String, void>> logUsage(int durationSeconds) async {
    try {
      final user = pbService.currentUser;
      if (user == null) return const Left('Sesi tidak valid.');
      
      await remoteDataSource.logApiUsage(user.id, 'groq_whisper', durationSeconds);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, String>> transcribeAudio(String filePath) async {
    try {
      final result = await remoteDataSource.transcribeAudio(filePath);
      return Right(result);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
