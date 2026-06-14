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
      systemPrompt = '''You are a professional and highly accurate translator.
Your task is to translate the user's text into $targetLanguage.
CRITICAL RULES:
1. You MUST translate the text into $targetLanguage regardless of the original language.
2. DO NOT output the original language.
3. DO NOT add any explanations, notes, or conversational text.
4. ONLY return the final translated text in $targetLanguage.''';
    } else {
      return const Left('Aksi tidak valid.');
    }

    return await repository.processText(text, systemPrompt);
  }
}
