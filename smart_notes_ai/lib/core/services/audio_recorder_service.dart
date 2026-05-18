import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentPath;
  DateTime? _startTime;
  int _accumulatedDuration = 0; // detik
  bool _isPaused = false;

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (await hasPermission()) {
      final Directory tempDir = await getTemporaryDirectory();
      _currentPath = '${tempDir.path}/smart_notes_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _accumulatedDuration = 0;
      _isPaused = false;
      _startTime = DateTime.now();

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _currentPath!,
      );
    } else {
      throw Exception('Izin mikrofon ditolak.');
    }
  }

  Future<void> pauseRecording() async {
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.pause();
      if (_startTime != null && !_isPaused) {
        _accumulatedDuration += DateTime.now().difference(_startTime!).inSeconds;
      }
      _isPaused = true;
    }
  }

  Future<void> resumeRecording() async {
    if (await _audioRecorder.isPaused()) {
      await _audioRecorder.resume();
      _startTime = DateTime.now();
      _isPaused = false;
    }
  }

  Future<Map<String, dynamic>?> stopRecording() async {
    final path = await _audioRecorder.stop();
    if (path != null) {
      int finalDuration = _accumulatedDuration;
      if (!_isPaused && _startTime != null) {
        finalDuration += DateTime.now().difference(_startTime!).inSeconds;
      }
      return {
        'path': path,
        'duration': finalDuration,
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
