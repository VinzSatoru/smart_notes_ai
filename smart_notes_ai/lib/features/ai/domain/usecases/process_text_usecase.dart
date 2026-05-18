import 'package:dartz/dartz.dart';
import '../repositories/ai_repository.dart';

class ProcessTextUseCase {
  final AiRepository repository;

  ProcessTextUseCase(this.repository);

  Future<Either<String, String>> execute(String text, String action) async {
    String systemPrompt = '';
    
    if (action == 'summary') {
      systemPrompt = 'Anda adalah asisten AI yang ahli dalam merangkum catatan. '
          'Buatlah rangkuman yang ringkas, jelas, dan memuat poin-poin penting '
          'dari teks berikut. Gunakan bahasa Indonesia.';
    } else if (action.startsWith('translate:')) {
      final targetLanguage = action.split(':')[1];
      systemPrompt = 'You are a professional and fluent translator. Translate the following '
          'text into fluent and natural-sounding $targetLanguage. Only return the translated text without any explanation.';
    } else {
      return const Left('Aksi tidak valid.');
    }

    return await repository.processText(text, systemPrompt);
  }
}
