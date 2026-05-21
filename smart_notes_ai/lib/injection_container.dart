import 'package:get_it/get_it.dart';
import 'package:smart_notes_ai/services/pocketbase_service.dart';
import 'package:smart_notes_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_notes_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:smart_notes_ai/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:smart_notes_ai/features/auth/domain/usecases/login_usecase.dart';
import 'package:smart_notes_ai/features/auth/domain/usecases/register_usecase.dart';
import 'package:smart_notes_ai/features/auth/domain/usecases/logout_usecase.dart';
import 'package:smart_notes_ai/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:smart_notes_ai/core/services/audio_recorder_service.dart';
import 'package:smart_notes_ai/features/ai/data/datasources/ai_remote_data_source.dart';
import 'package:smart_notes_ai/features/ai/data/repositories/ai_repository_impl.dart';
import 'package:smart_notes_ai/features/ai/domain/repositories/ai_repository.dart';
import 'package:smart_notes_ai/features/ai/domain/usecases/transcribe_audio_usecase.dart';
import 'package:smart_notes_ai/features/ai/domain/usecases/process_text_usecase.dart';
import 'package:smart_notes_ai/features/ai/presentation/bloc/ai_bloc.dart';

import 'package:smart_notes_ai/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:smart_notes_ai/features/notes/domain/usecases/fetch_notes_usecase.dart';
import 'package:smart_notes_ai/features/notes/domain/usecases/fetch_categories_usecase.dart';
import 'package:smart_notes_ai/features/notes/domain/usecases/delete_note_usecase.dart';
import 'package:smart_notes_ai/features/notes/domain/usecases/toggle_pin_usecase.dart';
import 'package:smart_notes_ai/features/notes/domain/usecases/add_note_usecase.dart';
import 'package:smart_notes_ai/features/notes/domain/usecases/update_note_usecase.dart';
import 'package:smart_notes_ai/features/notes/domain/usecases/add_category_usecase.dart';
import 'package:smart_notes_ai/features/notes/domain/usecases/toggle_favorite_usecase.dart';
import 'package:smart_notes_ai/features/notes/domain/usecases/toggle_archive_usecase.dart';
import 'package:smart_notes_ai/features/notes/domain/repositories/notes_repository.dart';
import 'package:smart_notes_ai/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:smart_notes_ai/features/notes/data/datasources/notes_remote_data_source.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Auth
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(pbService: sl()),
  );

  // --- Features - Notes ---
  // Bloc
  sl.registerFactory(
    () => NotesBloc(
      fetchNotesUseCase: sl(),
      fetchCategoriesUseCase: sl(),
      deleteNoteUseCase: sl(),
      togglePinUseCase: sl(),
      addNoteUseCase: sl(),
      updateNoteUseCase: sl(),
      addCategoryUseCase: sl(),
      toggleFavoriteUseCase: sl(),
      toggleArchiveUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => FetchNotesUseCase(sl()));
  sl.registerLazySingleton(() => FetchCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => DeleteNoteUseCase(sl()));
  sl.registerLazySingleton(() => TogglePinUseCase(sl()));
  sl.registerLazySingleton(() => AddNoteUseCase(sl()));
  sl.registerLazySingleton(() => UpdateNoteUseCase(sl()));
  sl.registerLazySingleton(() => AddCategoryUseCase(sl()));
  sl.registerLazySingleton(() => ToggleFavoriteUseCase(sl()));
  sl.registerLazySingleton(() => ToggleArchiveUseCase(sl()));

  // Repository
  sl.registerLazySingleton<NotesRepository>(
    () => NotesRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<NotesRemoteDataSource>(
    () => NotesRemoteDataSourceImpl(pbService: sl()),
  );

  // --- Features - AI ---
  // Bloc
  sl.registerFactory(
    () => AiBloc(
      aiRepository: sl(),
      transcribeAudioUseCase: sl(),
      processTextUseCase: sl(),
      audioService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => TranscribeAudioUseCase(sl()));
  sl.registerLazySingleton(() => ProcessTextUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AiRepository>(
    () => AiRepositoryImpl(remoteDataSource: sl(), pbService: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AiRemoteDataSource>(
    () => AiRemoteDataSourceImpl(pbService: sl()),
  );

  // Services
  sl.registerLazySingleton(() => AudioRecorderService());

  // Core & External
  sl.registerLazySingleton(() => PocketBaseService());
}
