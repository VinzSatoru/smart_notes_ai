import 'package:dartz/dartz.dart';
import '../entities/usage_status.dart';

abstract class AiRepository {
  Future<Either<String, UsageStatus>> checkUsageQuota();
  Future<Either<String, String>> transcribeAudio(String filePath);
  Future<Either<String, void>> logUsage(int durationSeconds);
}
