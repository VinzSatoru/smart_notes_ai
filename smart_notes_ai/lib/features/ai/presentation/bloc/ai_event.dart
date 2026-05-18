import 'package:equatable/equatable.dart';

abstract class AiEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckQuotaAndStartRecording extends AiEvent {}
class StopRecordingAndTranscribe extends AiEvent {}
class PauseRecording extends AiEvent {}
class ResumeRecording extends AiEvent {}
class CancelRecording extends AiEvent {}
class ResetAiState extends AiEvent {}

class ProcessTextRequested extends AiEvent {
  final String text;
  final String action; // 'summary' or 'translate'

  ProcessTextRequested({required this.text, required this.action});

  @override
  List<Object?> get props => [text, action];
}
