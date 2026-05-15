class ApiConstants {
  // Secara ideal ini harus disimpan di .env atau server, 
  // namun untuk keperluan prototipe disimpan di sini.
  static const String groqApiKey = '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';
  static const String groqTranscriptionsUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';
  
  // Model AI yang sangat cepat dan murah untuk speech-to-text
  static const String groqWhisperModel = 'whisper-large-v3';
}
