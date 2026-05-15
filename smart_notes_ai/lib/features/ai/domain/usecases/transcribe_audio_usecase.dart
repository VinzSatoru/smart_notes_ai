import 'package:dartz/dartz.dart';
import 'package:smart_notes_ai/features/ai/domain/repositories/ai_repository.dart';

class TranscribeAudioUseCase {
  final AiRepository repository;

  TranscribeAudioUseCase(this.repository);

  /// Menjalankan alur lengkap:
  /// 1. Cek Kuota
  /// 2. Jika diizinkan, lakukan transkripsi
  /// 3. Jika transkripsi berhasil, rekam usage log
  Future<Either<String, String>> call(String filePath, int durationSeconds) async {
    // 1. Cek Kuota
    final quotaCheck = await repository.checkUsageQuota();
    
    return quotaCheck.fold(
      (failure) => Left(failure),
      (status) async {
        if (!status.isAllowed) {
          return Left(status.message); // Return pesan kuota habis
        }

        // 2. Transkripsi
        final transcriptionResult = await repository.transcribeAudio(filePath);
        
        return transcriptionResult.fold(
          (failure) => Left(failure),
          (text) async {
            // 3. Log Usage jika berhasil
            await repository.logUsage(durationSeconds);
            return Right(text);
          }
        );
      }
    );
  }
}
