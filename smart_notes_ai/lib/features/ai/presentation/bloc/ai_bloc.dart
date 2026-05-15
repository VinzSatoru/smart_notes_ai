import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_notes_ai/core/services/audio_recorder_service.dart';
import 'package:smart_notes_ai/features/ai/domain/repositories/ai_repository.dart';
import 'package:smart_notes_ai/features/ai/domain/usecases/transcribe_audio_usecase.dart';
import 'ai_event.dart';
import 'ai_state.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final AiRepository aiRepository;
  final TranscribeAudioUseCase transcribeAudioUseCase;
  final AudioRecorderService audioService;

  AiBloc({
    required this.aiRepository,
    required this.transcribeAudioUseCase,
    required this.audioService,
  }) : super(AiIdle()) {
    on<CheckQuotaAndStartRecording>(_onCheckQuotaAndStart);
    on<StopRecordingAndTranscribe>(_onStopAndTranscribe);
    on<CancelRecording>(_onCancelRecording);
    on<ResetAiState>((event, emit) => emit(AiIdle()));
  }

  Future<void> _onCheckQuotaAndStart(CheckQuotaAndStartRecording event, Emitter<AiState> emit) async {
    emit(AiCheckingQuota());
    
    // Cek kuota terlebih dahulu
    final quotaCheck = await aiRepository.checkUsageQuota();
    
    await quotaCheck.fold(
      (failure) async {
        emit(AiFailure(message: failure));
      },
      (status) async {
        if (!status.isAllowed) {
          emit(AiFailure(message: status.message, isQuotaExceeded: true));
        } else {
          try {
            await audioService.startRecording();
            emit(AiRecording());
          } catch (e) {
            emit(AiFailure(message: 'Gagal memulai rekaman: $e'));
          }
        }
      }
    );
  }

  Future<void> _onStopAndTranscribe(StopRecordingAndTranscribe event, Emitter<AiState> emit) async {
    if (state is! AiRecording) return;
    
    emit(AiTranscribing());
    
    try {
      final result = await audioService.stopRecording();
      if (result != null) {
        final String path = result['path'];
        final int duration = result['duration'];
        
        // Batasan rekaman 10 menit
        if (duration > 600) {
          emit(AiFailure(message: 'Rekaman melebihi batas 10 menit.'));
          return;
        }

        if (duration < 1) {
          emit(AiFailure(message: 'Rekaman terlalu singkat.'));
          return;
        }

        final transcriptionResult = await transcribeAudioUseCase.call(path, duration);
        
        transcriptionResult.fold(
          (failure) => emit(AiFailure(message: failure)),
          (text) => emit(AiSuccess(text: text)),
        );
      } else {
        emit(AiFailure(message: 'Gagal menyimpan rekaman.'));
      }
    } catch (e) {
      emit(AiFailure(message: 'Terjadi kesalahan: $e'));
    }
  }

  Future<void> _onCancelRecording(CancelRecording event, Emitter<AiState> emit) async {
    await audioService.cancelRecording();
    emit(AiIdle());
  }
}
