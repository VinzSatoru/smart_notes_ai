import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String groqTranscriptionsUrl =
      'https://api.groq.com/openai/v1/audio/transcriptions';
  static const String groqChatUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // Model AI untuk speech-to-text
  static const String groqWhisperModel = 'whisper-large-v3';

  // Model AI untuk text processing (super cepat & cerdas)
  static const String groqTextModel = 'llama-3.1-8b-instant';
}
