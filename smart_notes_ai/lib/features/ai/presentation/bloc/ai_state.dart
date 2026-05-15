import 'package:equatable/equatable.dart';

abstract class AiState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AiIdle extends AiState {}
class AiCheckingQuota extends AiState {}
class AiRecording extends AiState {}
class AiTranscribing extends AiState {}
class AiSuccess extends AiState {
  final String text;
  AiSuccess({required this.text});
  @override
  List<Object?> get props => [text];
}
class AiFailure extends AiState {
  final String message;
  final bool isQuotaExceeded;
  AiFailure({required this.message, this.isQuotaExceeded = false});
  @override
  List<Object?> get props => [message, isQuotaExceeded];
}
