import 'package:dartz/dartz.dart';
import '../entities/usage_status.dart';

abstract class AiRepository {
  Future<Either<String, UsageStatus>> checkUsageQuota({String endpoint = 'groq_whisper'});
  Future<Either<String, String>> transcribeAudio(String filePath);
  Future<Either<String, void>> logUsage(int durationSeconds, {String endpoint = 'groq_whisper'});
  Future<Either<String, String>> processText(String text, String systemPrompt);
}
