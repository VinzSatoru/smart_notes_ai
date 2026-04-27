import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:intl/intl.dart';

class NoteCard extends StatelessWidget {
  final RecordModel note;
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
    // Ambil data dari model
    final title = note.getStringValue('title');
    final content = note.getStringValue('content_text');
    final isPinned = note.getBoolValue('is_pinned');
    final createdStr = note.getStringValue('created');
    
    // Format tanggal
    String dateFormatted = '';
    if (createdStr.isNotEmpty) {
      try {
        final date = DateTime.parse(createdStr);
        dateFormatted = DateFormat('d MMM yyyy').format(date);
      } catch (e) {
        dateFormatted = createdStr.split(' ')[0];
      }
    }

    return Card(
      elevation: 0,
      color: Colors.teal.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.shade100, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Penting untuk masonry grid
            children: [
              // Header: Title dan Pin Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title.isNotEmpty ? title : 'Tanpa Judul',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isPinned)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.push_pin,
                        size: 18,
                        color: Colors.teal,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Isi Catatan
              if (content.isNotEmpty)
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  maxLines: 6, // Maksimal 6 baris untuk grid asimetris
                  overflow: TextOverflow.ellipsis,
                ),
              if (content.isNotEmpty) const SizedBox(height: 12),
              
              // Footer: Tanggal
              Text(
                dateFormatted,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
