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

class DeleteNoteEvent extends NotesEvent {
  final String noteId;
  final String userId;

  const DeleteNoteEvent({required this.noteId, required this.userId});

  @override
  List<Object> get props => [noteId, userId];
}

class TogglePinEvent extends NotesEvent {
  final Note note;
  final String userId;

  const TogglePinEvent({required this.note, required this.userId});

  @override
  List<Object> get props => [note, userId];
}

class AddNoteEvent extends NotesEvent {
  final String userId;
  final String title;
  final String contentText;
  final String categoryId;

  const AddNoteEvent({
    required this.userId,
    required this.title,
    required this.contentText,
    required this.categoryId,
  });

  @override
  List<Object> get props => [userId, title, contentText, categoryId];
}

class UpdateNoteEvent extends NotesEvent {
  final String noteId;
  final String title;
  final String contentText;
  final String categoryId;
  final String userId;

  const UpdateNoteEvent({
    required this.noteId,
    required this.title,
    required this.contentText,
    required this.categoryId,
    required this.userId,
  });

  @override
  List<Object> get props => [noteId, title, contentText, categoryId, userId];
}
