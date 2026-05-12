import 'package:equatable/equatable.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/category.dart';

enum NotesStatus { initial, loading, success, failure }

class NotesState extends Equatable {
  final NotesStatus status;
  final List<Note> notes;
  final List<Category> categories;
  final String selectedCategoryId;
  final bool isGridView;
  final String errorMessage;

  const NotesState({
    this.status = NotesStatus.initial,
    this.notes = const [],
    this.categories = const [],
    this.selectedCategoryId = 'all',
    this.isGridView = true,
    this.errorMessage = '',
  });

  NotesState copyWith({
    NotesStatus? status,
    List<Note>? notes,
    List<Category>? categories,
    String? selectedCategoryId,
    bool? isGridView,
    String? errorMessage,
  }) {
    return NotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isGridView: isGridView ?? this.isGridView,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notes,
        categories,
        selectedCategoryId,
        isGridView,
        errorMessage,
      ];
}
