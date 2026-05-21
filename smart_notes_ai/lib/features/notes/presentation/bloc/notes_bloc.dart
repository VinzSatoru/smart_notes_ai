import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/fetch_notes_usecase.dart';
import '../../domain/usecases/fetch_categories_usecase.dart';
import '../../domain/usecases/delete_note_usecase.dart';
import '../../domain/usecases/toggle_pin_usecase.dart';
import '../../domain/usecases/add_note_usecase.dart';
import '../../domain/usecases/update_note_usecase.dart';
import '../../domain/usecases/add_category_usecase.dart';
import 'notes_event.dart';
import 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final FetchNotesUseCase fetchNotesUseCase;
  final FetchCategoriesUseCase fetchCategoriesUseCase;
  final DeleteNoteUseCase deleteNoteUseCase;
  final TogglePinUseCase togglePinUseCase;
  final AddNoteUseCase addNoteUseCase;
  final UpdateNoteUseCase updateNoteUseCase;
  final AddCategoryUseCase addCategoryUseCase;

  NotesBloc({
    required this.fetchNotesUseCase,
    required this.fetchCategoriesUseCase,
    required this.deleteNoteUseCase,
    required this.togglePinUseCase,
    required this.addNoteUseCase,
    required this.updateNoteUseCase,
    required this.addCategoryUseCase,
  }) : super(const NotesState()) {
    on<FetchCategoriesAndNotes>(_onFetchCategoriesAndNotes);
    on<FilterNotesByCategory>(_onFilterNotesByCategory);
    on<ToggleViewMode>(_onToggleViewMode);
    on<DeleteNoteEvent>(_onDeleteNote);
    on<DeleteMultipleNotesEvent>(_onDeleteMultipleNotes);
    on<TogglePinEvent>(_onTogglePin);
    on<AddNoteEvent>(_onAddNote);
    on<UpdateNoteEvent>(_onUpdateNote);
    on<AddCategoryEvent>(_onAddCategory);
  }

  Future<void> _onFetchCategoriesAndNotes(
    FetchCategoriesAndNotes event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(status: NotesStatus.loading));

    final categoriesResult = await fetchCategoriesUseCase(FetchCategoriesParams(userId: event.userId));
    
    // We want to fetch notes too, default category is 'all'
    final notesResult = await fetchNotesUseCase(
      FetchNotesParams(userId: event.userId, categoryId: state.selectedCategoryId),
    );

    categoriesResult.fold(
      (failure) => emit(state.copyWith(status: NotesStatus.failure, errorMessage: failure.message)),
      (categories) async {
        // Seeding base categories jika masih kosong
        if (categories.isEmpty) {
          // Buat kategori default
          await addCategoryUseCase(AddCategoryParams(userId: event.userId, name: 'Meeting'));
          await addCategoryUseCase(AddCategoryParams(userId: event.userId, name: 'Materi'));
          // Panggil lagi untuk memuat yang baru
          add(FetchCategoriesAndNotes(userId: event.userId));
          return;
        }

        notesResult.fold(
          (failure) => emit(state.copyWith(status: NotesStatus.failure, errorMessage: failure.message)),
          (notes) => emit(state.copyWith(
            status: NotesStatus.success,
            categories: categories,
            notes: notes,
          )),
        );
      },
    );
  }

  Future<void> _onAddCategory(
    AddCategoryEvent event,
    Emitter<NotesState> emit,
  ) async {
    final result = await addCategoryUseCase(AddCategoryParams(userId: event.userId, name: event.name));

    result.fold(
      (failure) => emit(state.copyWith(status: NotesStatus.failure, errorMessage: failure.message)),
      (_) {
        // Refresh categories
        add(FetchCategoriesAndNotes(userId: event.userId));
      },
    );
  }

  Future<void> _onFilterNotesByCategory(
    FilterNotesByCategory event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(status: NotesStatus.loading, selectedCategoryId: event.categoryId));

    final notesResult = await fetchNotesUseCase(
      FetchNotesParams(userId: event.userId, categoryId: event.categoryId),
    );

    notesResult.fold(
      (failure) => emit(state.copyWith(status: NotesStatus.failure, errorMessage: failure.message)),
      (notes) => emit(state.copyWith(status: NotesStatus.success, notes: notes)),
    );
  }

  void _onToggleViewMode(
    ToggleViewMode event,
    Emitter<NotesState> emit,
  ) {
    emit(state.copyWith(isGridView: !state.isGridView));
  }

  Future<void> _onDeleteNote(
    DeleteNoteEvent event,
    Emitter<NotesState> emit,
  ) async {
    final result = await deleteNoteUseCase(DeleteNoteParams(noteId: event.noteId));

    result.fold(
      (failure) => emit(state.copyWith(status: NotesStatus.failure, errorMessage: failure.message)),
      (_) {
        // Refetch notes to ensure state is synchronized with DB
        add(FilterNotesByCategory(categoryId: state.selectedCategoryId, userId: event.userId));
      },
    );
  }

  Future<void> _onDeleteMultipleNotes(
    DeleteMultipleNotesEvent event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(status: NotesStatus.loading));
    try {
      // Execute deletions in parallel
      await Future.wait(event.noteIds.map((id) => deleteNoteUseCase(DeleteNoteParams(noteId: id))));
      
      // Refetch notes
      add(FilterNotesByCategory(categoryId: state.selectedCategoryId, userId: event.userId));
    } catch (e) {
      emit(state.copyWith(status: NotesStatus.failure, errorMessage: 'Gagal menghapus beberapa catatan'));
      // Still try to refetch to get the latest accurate state
      add(FilterNotesByCategory(categoryId: state.selectedCategoryId, userId: event.userId));
    }
  }

  Future<void> _onTogglePin(
    TogglePinEvent event,
    Emitter<NotesState> emit,
  ) async {
    final result = await togglePinUseCase(TogglePinParams(note: event.note));

    result.fold(
      (failure) => emit(state.copyWith(status: NotesStatus.failure, errorMessage: failure.message)),
      (_) {
        // Refetch notes to ensure state is synchronized with DB
        add(FilterNotesByCategory(categoryId: state.selectedCategoryId, userId: event.userId));
      },
    );
  }

  Future<void> _onAddNote(
    AddNoteEvent event,
    Emitter<NotesState> emit,
  ) async {
    final result = await addNoteUseCase(AddNoteParams(
      userId: event.userId,
      title: event.title,
      contentText: event.contentText,
      categoryId: event.categoryId,
      aiSummary: event.aiSummary,
      aiTranslation: event.aiTranslation,
    ));

    result.fold(
      (failure) => emit(state.copyWith(status: NotesStatus.failure, errorMessage: failure.message)),
      (_) {
        // Refetch
        add(FilterNotesByCategory(categoryId: state.selectedCategoryId, userId: event.userId));
      },
    );
  }

  Future<void> _onUpdateNote(
    UpdateNoteEvent event,
    Emitter<NotesState> emit,
  ) async {
    final result = await updateNoteUseCase(UpdateNoteParams(
      noteId: event.noteId,
      title: event.title,
      contentText: event.contentText,
      categoryId: event.categoryId,
      aiSummary: event.aiSummary,
      aiTranslation: event.aiTranslation,
    ));

    result.fold(
      (failure) => emit(state.copyWith(status: NotesStatus.failure, errorMessage: failure.message)),
      (_) {
        // Refetch
        add(FilterNotesByCategory(categoryId: state.selectedCategoryId, userId: event.userId));
      },
    );
  }
}
