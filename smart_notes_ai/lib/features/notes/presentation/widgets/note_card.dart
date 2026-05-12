import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final title = note.title;
    final content = note.contentText;
    final isPinned = note.isPinned;
    final createdStr = note.created;
    
    // Format tanggal
    String dateFormatted = '';
    if (createdStr.isNotEmpty) {
      try {
        DateTime dt = DateTime.parse(createdStr).toLocal();
        dateFormatted = DateFormat('dd MMM yyyy').format(dt);
      } catch (_) {
        dateFormatted = createdStr;
      }
    }

    // Modern color palette
    final colors = [
      const Color(0xFFF0F4FF), // Light Blue
      const Color(0xFFFFF0F5), // Light Pink
      const Color(0xFFF0FFF4), // Light Green
      const Color(0xFFFFF9F0), // Light Orange
      const Color(0xFFF9F0FF), // Light Purple
    ];
    
    // Pick color based on ID length to make it pseudo-random but consistent
    final colorIndex = note.id.length % colors.length;
    final cardColor = colors[colorIndex];

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPinned)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Icon(Icons.push_pin, size: 16, color: Color(0xFF4F64F2)),
                ),
              if (title.isNotEmpty)
                Hero(
                  tag: 'note_title_${note.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              if (title.isNotEmpty && content.isNotEmpty)
                const SizedBox(height: 8),
              if (content.isNotEmpty)
                Hero(
                  tag: 'note_content_${note.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormatted,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (note.categoryId.isNotEmpty && note.categoryId != 'all')
                    const Icon(Icons.folder_outlined, size: 14, color: Colors.black38),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
