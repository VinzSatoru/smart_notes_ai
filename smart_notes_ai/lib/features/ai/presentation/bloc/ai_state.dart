import 'package:equatable/equatable.dart';

abstract class AiState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AiIdle extends AiState {}
class AiCheckingQuota extends AiState {}
class AiRecording extends AiState {}
class AiRecordingPaused extends AiState {}
class AiTranscribing extends AiState {}
class AiProcessingText extends AiState {}
class AiSuccess extends AiState {
  final String text;
  final String action; // 'transcribe', 'summary', or 'translate:xx'
  AiSuccess({required this.text, required this.action});
  @override
  List<Object?> get props => [text, action];
}
class AiFailure extends AiState {
  final String message;
  final bool isQuotaExceeded;
  AiFailure({required this.message, this.isQuotaExceeded = false});
  @override
  List<Object?> get props => [message, isQuotaExceeded];
}
