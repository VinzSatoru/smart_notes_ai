import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/note.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter/services.dart';

class NoteCard extends StatefulWidget {
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
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _isPressed = false;
  Color get navyColor => Theme.of(context).colorScheme.onSurface;
  Color get primaryColor => Theme.of(context).primaryColor;
  Color get cardColor => Theme.of(context).cardTheme.color ?? Colors.white;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final title = note.title;
    final content = note.contentText;
    final isPinned = note.isPinned;
    final createdStr = note.created;
    
    String displayContent = content;
    if (content.trim().startsWith('[') && content.trim().endsWith(']')) {
      try {
        final decoded = jsonDecode(content);
        final doc = quill.Document.fromJson(decoded);
        displayContent = doc.toPlainText().trim();
      } catch (e) {
        // Fallback to original content
      }
    }
    
    // Format tanggal
    String dateFormatted = '';
    if (createdStr.isNotEmpty) {
      try {
        DateTime dt = DateTime.parse(createdStr).toLocal();
        dateFormatted = DateFormat('dd MMM yyyy').format(dt).toUpperCase();
      } catch (_) {
        dateFormatted = createdStr;
      }
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Hero(
          tag: 'note_card_${note.id}',
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: navyColor.withValues(alpha: 0.05), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title.isEmpty ? 'Catatan Tanpa Judul' : title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: navyColor,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (note.isFavorite)
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                      if (note.isFavorite && isPinned) const SizedBox(width: 4),
                      if (isPinned)
                        Icon(Icons.push_pin_rounded, size: 14, color: primaryColor),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (displayContent.isNotEmpty)
                Text(
                  displayContent,
                  style: TextStyle(
                    fontSize: 14,
                    color: navyColor.withValues(alpha: 0.5),
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormatted,
                    style: TextStyle(
                      fontSize: 10,
                      color: navyColor.withValues(alpha: 0.3),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
