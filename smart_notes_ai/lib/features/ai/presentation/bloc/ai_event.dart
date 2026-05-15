import 'package:equatable/equatable.dart';

abstract class AiEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckQuotaAndStartRecording extends AiEvent {}
class StopRecordingAndTranscribe extends AiEvent {}
class CancelRecording extends AiEvent {}
class ResetAiState extends AiEvent {}
