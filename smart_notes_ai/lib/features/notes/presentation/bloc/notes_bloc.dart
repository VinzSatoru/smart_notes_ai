import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/fetch_notes_usecase.dart';
import '../../domain/usecases/fetch_categories_usecase.dart';
import '../../domain/usecases/delete_note_usecase.dart';
import '../../domain/usecases/toggle_pin_usecase.dart';
import '../../domain/usecases/add_note_usecase.dart';
import '../../domain/usecases/update_note_usecase.dart';
import '../../domain/usecases/add_category_usecase.dart';
import '../../domain/usecases/toggle_favorite_usecase.dart';
import '../../domain/usecases/toggle_archive_usecase.dart';
import '../../domain/usecases/move_to_trash_usecase.dart';
import '../../domain/usecases/restore_note_usecase.dart';
import 'notes_event.dart';
import 'notes_state.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/category.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final FetchNotesUseCase fetchNotesUseCase;
  final FetchCategoriesUseCase fetchCategoriesUseCase;
  final DeleteNoteUseCase deleteNoteUseCase;
  final TogglePinUseCase togglePinUseCase;
  final AddNoteUseCase addNoteUseCase;
  final UpdateNoteUseCase updateNoteUseCase;
  final AddCategoryUseCase addCategoryUseCase;
  final ToggleFavoriteUseCase toggleFavoriteUseCase;
  final ToggleArchiveUseCase toggleArchiveUseCase;
  final MoveToTrashUseCase moveToTrashUseCase;
  final RestoreNoteUseCase restoreNoteUseCase;

  NotesBloc({
    required this.fetchNotesUseCase,
    required this.fetchCategoriesUseCase,
    required this.deleteNoteUseCase,
    required this.togglePinUseCase,
    required this.addNoteUseCase,
    required this.updateNoteUseCase,
    required this.addCategoryUseCase,
    required this.toggleFavoriteUseCase,
    required this.toggleArchiveUseCase,
    required this.moveToTrashUseCase,
    required this.restoreNoteUseCase,
  }) : super(const NotesState()) {
    on<FetchCategoriesAndNotes>(_onFetchCategoriesAndNotes);
    on<FilterNotesByCategory>(_onFilterNotesByCategory);
    on<SearchNotes>(_onSearchNotes);
    on<ToggleViewMode>(_onToggleViewMode);
    on<PermanentDeleteNoteEvent>(_onPermanentDeleteNote);
    on<MoveToTrashEvent>(_onMoveToTrash);
    on<RestoreNoteEvent>(_onRestoreNote);
    on<DeleteMultipleNotesEvent>(_onDeleteMultipleNotes);
    on<TogglePinEvent>(_onTogglePin);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<ToggleArchiveEvent>(_onToggleArchive);
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

        // Deduplikasi kategori berdasarkan nama untuk mengatasi bug double
        final uniqueCategories = <Category>[];
        final seenNames = <String>{};
        for (var cat in categories) {
          final normalized = cat.name.trim().toLowerCase();
          if (!seenNames.contains(normalized)) {
            uniqueCategories.add(cat);
            seenNames.add(normalized);
          }
        }

        notesResult.fold(
          (failure) => emit(state.copyWith(status: NotesStatus.failure, errorMessage: failure.message)),
          (notes) => emit(state.copyWith(
            status: NotesStatus.success,
            categories: uniqueCategories,
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

  void _onSearchNotes(
    SearchNotes event,
    Emitter<NotesState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onToggleViewMode(
    ToggleViewMode event,
    Emitter<NotesState> emit,
  ) {
    emit(state.copyWith(isGridView: !state.isGridView));
  }

  Future<void> _onPermanentDeleteNote(
    PermanentDeleteNoteEvent event,
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

  Future<void> _onMoveToTrash(
    MoveToTrashEvent event,
    Emitter<NotesState> emit,
  ) async {
    final updatedNotes = state.notes.map((note) {
      if (note.id == event.note.id) {
        return Note(
          id: note.id, title: note.title, contentText: note.contentText,
          isPinned: note.isPinned, isFavorite: note.isFavorite, isArchived: note.isArchived,
          isTrashed: true, created: note.created, categoryId: note.categoryId,
          aiSummary: note.aiSummary, aiTranslation: note.aiTranslation,
        );
      }
      return note;
    }).toList();

    emit(state.copyWith(notes: updatedNotes));

    final result = await moveToTrashUseCase(event.note);
    result.fold(
      (failure) { emit(state.copyWith(notes: state.notes)); },
      (_) {},
    );
  }

  Future<void> _onRestoreNote(
    RestoreNoteEvent event,
    Emitter<NotesState> emit,
  ) async {
    final updatedNotes = state.notes.map((note) {
      if (note.id == event.note.id) {
        return Note(
          id: note.id, title: note.title, contentText: note.contentText,
          isPinned: note.isPinned, isFavorite: note.isFavorite, isArchived: note.isArchived,
          isTrashed: false, created: note.created, categoryId: note.categoryId,
          aiSummary: note.aiSummary, aiTranslation: note.aiTranslation,
        );
      }
      return note;
    }).toList();

    emit(state.copyWith(notes: updatedNotes));

    final result = await restoreNoteUseCase(event.note);
    result.fold(
      (failure) { emit(state.copyWith(notes: state.notes)); },
      (_) {},
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

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<NotesState> emit,
  ) async {
    // Optimistic update
    final updatedNotes = state.notes.map((note) {
      if (note.id == event.note.id) {
        return Note(
          id: note.id,
          title: note.title,
          contentText: note.contentText,
          isPinned: note.isPinned,
          isFavorite: !note.isFavorite,
          isArchived: note.isArchived,
          isTrashed: note.isTrashed,
          created: note.created,
          categoryId: note.categoryId,
          aiSummary: note.aiSummary,
          aiTranslation: note.aiTranslation,
        );
      }
      return note;
    }).toList();

    emit(state.copyWith(notes: updatedNotes));

    final result = await toggleFavoriteUseCase(event.note);

    result.fold(
      (failure) {
        // Jika gagal di server, kembalikan ke state semula
        emit(state.copyWith(notes: state.notes));
      },
      (_) {},
    );
  }

  Future<void> _onToggleArchive(
    ToggleArchiveEvent event,
    Emitter<NotesState> emit,
  ) async {
    // Optimistic update
    final updatedNotes = state.notes.map((note) {
      if (note.id == event.note.id) {
        return Note(
          id: note.id,
          title: note.title,
          contentText: note.contentText,
          isPinned: note.isPinned,
          isFavorite: note.isFavorite,
          isArchived: !note.isArchived,
          isTrashed: note.isTrashed,
          created: note.created,
          categoryId: note.categoryId,
          aiSummary: note.aiSummary,
          aiTranslation: note.aiTranslation,
        );
      }
      return note;
    }).toList();

    emit(state.copyWith(notes: updatedNotes));

    final result = await toggleArchiveUseCase(event.note);

    result.fold(
      (failure) {
        // Jika gagal di server, kembalikan ke state semula
        emit(state.copyWith(notes: state.notes));
      },
      (_) {},
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
