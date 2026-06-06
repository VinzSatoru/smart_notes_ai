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

  // DOKU Payment Gateway (Sandbox)
  static String get dokuClientId => dotenv.env['DOKU_CLIENT_ID'] ?? '';
  static String get dokuSecretKey => dotenv.env['DOKU_SECRET_KEY'] ?? '';
  static const String dokuBaseUrl = 'https://api-sandbox.doku.com';
}
