import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_notes_ai/core/services/audio_recorder_service.dart';
import 'package:smart_notes_ai/features/ai/domain/repositories/ai_repository.dart';
import 'package:smart_notes_ai/features/ai/domain/usecases/transcribe_audio_usecase.dart';
import 'package:smart_notes_ai/features/ai/domain/usecases/process_text_usecase.dart';
import 'ai_event.dart';
import 'ai_state.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final AiRepository aiRepository;
  final TranscribeAudioUseCase transcribeAudioUseCase;
  final ProcessTextUseCase processTextUseCase;
  final AudioRecorderService audioService;

  AiBloc({
    required this.aiRepository,
    required this.transcribeAudioUseCase,
    required this.processTextUseCase,
    required this.audioService,
  }) : super(AiIdle()) {
    on<CheckQuotaAndStartRecording>(_onCheckQuotaAndStart);
    on<PauseRecording>(_onPauseRecording);
    on<ResumeRecording>(_onResumeRecording);
    on<StopRecordingAndTranscribe>(_onStopAndTranscribe);
    on<CancelRecording>(_onCancelRecording);
    on<ProcessTextRequested>(_onProcessTextRequested);
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

  Future<void> _onPauseRecording(PauseRecording event, Emitter<AiState> emit) async {
    if (state is AiRecording) {
      await audioService.pauseRecording();
      emit(AiRecordingPaused());
    }
  }

  Future<void> _onResumeRecording(ResumeRecording event, Emitter<AiState> emit) async {
    if (state is AiRecordingPaused) {
      await audioService.resumeRecording();
      emit(AiRecording());
    }
  }

  Future<void> _onStopAndTranscribe(StopRecordingAndTranscribe event, Emitter<AiState> emit) async {
    if (state is! AiRecording && state is! AiRecordingPaused) return;
    
    emit(AiTranscribing());
    
    try {
      final result = await audioService.stopRecording();
      if (result != null) {
        final String path = result['path'];
        final int duration = result['duration'];
        
        // Batasan rekaman 5 menit (300 detik)
        if (duration > 300) {
          emit(AiFailure(message: 'Rekaman melebihi batas 5 menit.'));
          return;
        }

        if (duration < 1) {
          emit(AiFailure(message: 'Rekaman terlalu singkat.'));
          return;
        }

        final transcriptionResult = await transcribeAudioUseCase.call(path, duration);
        
        transcriptionResult.fold(
          (failure) => emit(AiFailure(message: failure)),
          (text) => emit(AiSuccess(text: text, action: 'transcribe')),
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

  Future<void> _onProcessTextRequested(ProcessTextRequested event, Emitter<AiState> emit) async {
    emit(AiProcessingText());

    // Hanya summary yang dibatasi kuota 5x
    if (event.action == 'summary') {
      final quotaCheck = await aiRepository.checkUsageQuota(endpoint: 'summary');

      if (quotaCheck.isLeft()) {
        final failure = quotaCheck.fold((l) => l, (r) => '');
        emit(AiFailure(message: failure));
        return;
      }

      final status = quotaCheck.fold((l) => null, (r) => r);
      if (status != null && !status.isAllowed) {
        emit(AiFailure(message: status.message, isQuotaExceeded: true));
        return;
      }
    }

    final result = await processTextUseCase.execute(event.text, event.action);
    
    await result.fold(
      (failure) async {
        emit(AiFailure(message: failure));
      },
      (processedText) async {
        if (event.action == 'summary') {
          await aiRepository.logUsage(0, endpoint: 'summary');
          emit(AiSuccess(text: processedText, action: 'summary'));
        } else if (event.action.startsWith('translate:')) {
          emit(AiSuccess(text: processedText, action: event.action));
        }
      }
    );
  }
}
