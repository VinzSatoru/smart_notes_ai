import 'package:equatable/equatable.dart';
import '../../domain/entities/note.dart';

abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object> get props => [];
}

class FetchCategoriesAndNotes extends NotesEvent {
  final String userId;

  const FetchCategoriesAndNotes({required this.userId});

  @override
  List<Object> get props => [userId];
}

class FilterNotesByCategory extends NotesEvent {
  final String categoryId;
  final String userId;

  const FilterNotesByCategory({required this.categoryId, required this.userId});

  @override
  List<Object> get props => [categoryId, userId];
}

class ToggleViewMode extends NotesEvent {}

class PermanentDeleteNoteEvent extends NotesEvent {
  final String noteId;
  final String userId;

  const PermanentDeleteNoteEvent({required this.noteId, required this.userId});

  @override
  List<Object> get props => [noteId, userId];
}

class MoveToTrashEvent extends NotesEvent {
  final Note note;

  const MoveToTrashEvent({required this.note});

  @override
  List<Object> get props => [note];
}

class RestoreNoteEvent extends NotesEvent {
  final Note note;

  const RestoreNoteEvent({required this.note});

  @override
  List<Object> get props => [note];
}

class DeleteMultipleNotesEvent extends NotesEvent {
  final List<String> noteIds;
  final String userId;

  const DeleteMultipleNotesEvent({required this.noteIds, required this.userId});

  @override
  List<Object> get props => [noteIds, userId];
}

class TogglePinEvent extends NotesEvent {
  final Note note;
  final String userId;

  const TogglePinEvent({required this.note, required this.userId});

  @override
  List<Object> get props => [note, userId];
}

class ToggleFavoriteEvent extends NotesEvent {
  final Note note;

  const ToggleFavoriteEvent({required this.note});

  @override
  List<Object> get props => [note];
}

class ToggleArchiveEvent extends NotesEvent {
  final Note note;

  const ToggleArchiveEvent({required this.note});

  @override
  List<Object> get props => [note];
}

class AddCategoryEvent extends NotesEvent {
  final String userId;
  final String name;

  const AddCategoryEvent({required this.userId, required this.name});

  @override
  List<Object> get props => [userId, name];
}

class AddNoteEvent extends NotesEvent {
  final String userId;
  final String title;
  final String contentText;
  final String categoryId;
  final String? aiSummary;
  final String? aiTranslation;

  const AddNoteEvent({
    required this.userId,
    required this.title,
    required this.contentText,
    required this.categoryId,
    this.aiSummary,
    this.aiTranslation,
  });

  @override
  List<Object> get props => [userId, title, contentText, categoryId, aiSummary ?? '', aiTranslation ?? ''];
}

class UpdateNoteEvent extends NotesEvent {
  final String noteId;
  final String title;
  final String contentText;
  final String categoryId;
  final String userId;
  final String? aiSummary;
  final String? aiTranslation;

  const UpdateNoteEvent({
    required this.noteId,
    required this.title,
    required this.contentText,
    required this.categoryId,
    required this.userId,
    this.aiSummary,
    this.aiTranslation,
  });

  @override
  List<Object> get props => [noteId, title, contentText, categoryId, userId, aiSummary ?? '', aiTranslation ?? ''];
}
