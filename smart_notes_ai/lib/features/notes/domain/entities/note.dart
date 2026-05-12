import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String title;
  final String contentText;
  final bool isPinned;
  final String created;
  final String categoryId;

  const Note({
    required this.id,
    required this.title,
    required this.contentText,
    required this.isPinned,
    required this.created,
    required this.categoryId,
  });

  @override
  List<Object?> get props => [id, title, contentText, isPinned, created, categoryId];
}
