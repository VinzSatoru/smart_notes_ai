import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_notes_ai/core/constants/api_constants.dart';
import 'package:smart_notes_ai/services/pocketbase_service.dart';

abstract class AiRemoteDataSource {
  Future<int> getTodayUsageCount(String userId, {String? endpoint});
  Future<void> logApiUsage(String userId, String endpoint, int durationSeconds);
  Future<String> transcribeAudio(String filePath);
  Future<String> processText(String text, String systemPrompt);
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  final PocketBaseService pbService;

  AiRemoteDataSourceImpl({required this.pbService});

  @override
  Future<int> getTodayUsageCount(String userId, {String? endpoint}) async {
    final now = DateTime.now();
    // Format tanggal awal hari ini untuk filter PocketBase (YYYY-MM-DD 00:00:00)
    final todayStart = DateTime(now.year, now.month, now.day).toUtc().toIso8601String().replaceAll('T', ' ').substring(0, 19);
    
    String filter = 'user_id = "$userId" && created >= "$todayStart"';
    if (endpoint != null) {
      filter += ' && endpoint = "$endpoint"';
    }

    try {
      final result = await pbService.pb.collection('api_usage_logs').getList(
        page: 1,
        perPage: 1,
        filter: filter,
      );
      return result.totalItems;
    } catch (e) {
      throw Exception('Gagal mendapatkan data kuota: $e');
    }
  }

  @override
  Future<void> logApiUsage(String userId, String endpoint, int durationSeconds) async {
    try {
      await pbService.pb.collection('api_usage_logs').create(body: {
        'user_id': userId,
        'endpoint': endpoint,
        'duration_seconds': durationSeconds,
      });

      // Update total ai_quota_used di tabel users
      final user = pbService.currentUser;
      if (user != null) {
        final currentQuota = user.getIntValue('ai_quota_used');
        await pbService.pb.collection('users').update(user.id, body: {
          'ai_quota_used': currentQuota + 1,
        });
      }
    } catch (e) {
      throw Exception('Gagal mencatat log penggunaan: $e');
    }
  }

  @override
  Future<String> transcribeAudio(String filePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.groqTranscriptionsUrl));
      request.headers['Authorization'] = 'Bearer ${ApiConstants.groqApiKey}';
      request.headers['User-Agent'] = 'SmartNotesAI/1.0.0 (Android)';
      
      request.fields['model'] = ApiConstants.groqWhisperModel;
      request.fields['response_format'] = 'json';
      request.fields['language'] = 'id'; // Memaksa AI mengenali bahasa Indonesia
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['text'] ?? '';
      } else {
        throw Exception('Groq API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal melakukan transkripsi: $e');
    }
  }

  @override
  Future<String> processText(String text, String systemPrompt) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.groqChatUrl),
        headers: {
          'Authorization': 'Bearer ${ApiConstants.groqApiKey}',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        },
        body: jsonEncode({
          'model': ApiConstants.groqTextModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': text}
          ],
          'temperature': 0.5,
          'max_tokens': 2048,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final content = json['choices'][0]['message']['content'];
        return content.toString().trim();
      } else {
        print('Groq API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Groq API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Groq API Exception: $e');
      throw Exception('Gagal memproses teks: $e');
    }
  }
}
