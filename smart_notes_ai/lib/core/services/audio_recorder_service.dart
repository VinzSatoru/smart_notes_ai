import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentPath;
  DateTime? _startTime;

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (await hasPermission()) {
      final Directory tempDir = await getTemporaryDirectory();
      _currentPath = '${tempDir.path}/smart_notes_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _startTime = DateTime.now();

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _currentPath!,
      );
    } else {
      throw Exception('Izin mikrofon ditolak.');
    }
  }

  Future<Map<String, dynamic>?> stopRecording() async {
    final path = await _audioRecorder.stop();
    if (path != null && _startTime != null) {
      final duration = DateTime.now().difference(_startTime!).inSeconds;
      return {
        'path': path,
        'duration': duration,
      };
    }
    return null;
  }

  Future<void> cancelRecording() async {
    await _audioRecorder.stop();
    if (_currentPath != null) {
      final file = File(_currentPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
