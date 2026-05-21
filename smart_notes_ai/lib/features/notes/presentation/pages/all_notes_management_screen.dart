import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/category.dart';
import 'note_editor_screen.dart';

class AllNotesManagementScreen extends StatefulWidget {
  final String userId;
  final bool filterFavorite;
  final bool filterArchive;
  final bool filterTrash;

  const AllNotesManagementScreen({
    super.key,
    required this.userId,
    this.filterFavorite = false,
    this.filterArchive = false,
    this.filterTrash = false,
  });

  @override
  State<AllNotesManagementScreen> createState() => _AllNotesManagementScreenState();
}

class _AllNotesManagementScreenState extends State<AllNotesManagementScreen> {
  final Set<String> _selectedNoteIds = {};
  bool _isSelectionMode = false;
  final Color primaryColor = const Color(0xFF4F64F2);
  final Color navyColor = const Color(0xFF1E293B);

  void _toggleSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
        if (_selectedNoteIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNoteIds.add(noteId);
        _isSelectionMode = true;
      }
    });
  }

  void _deleteSelectedNotes() {
    if (_selectedNoteIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Catatan', style: TextStyle(color: navyColor, fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus ${_selectedNoteIds.length} catatan terpilih? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              context.read<NotesBloc>().add(DeleteMultipleNotesEvent(
                noteIds: _selectedNoteIds.toList(),
                userId: widget.userId,
              ));
              setState(() {
                _selectedNoteIds.clear();
                _isSelectionMode = false;
              });
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Catatan berhasil dihapus'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String categoryId, List<Category> categories) {
    if (categoryId.isEmpty || categoryId == 'all') return 'Tanpa Kategori';
    try {
      return categories.firstWhere((c) => c.id == categoryId).name;
    } catch (_) {
      return 'Tanpa Kategori';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: navyColor),
          onPressed: () {
            if (_isSelectionMode) {
              setState(() {
                _isSelectionMode = false;
                _selectedNoteIds.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _isSelectionMode 
            ? '${_selectedNoteIds.length} Dipilih' 
            : (widget.filterTrash 
                ? 'Sampah' 
                : (widget.filterArchive 
                    ? 'Catatan Arsip' 
                    : (widget.filterFavorite ? 'Catatan Favorit' : 'Semua Catatan'))),
          style: TextStyle(color: navyColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (!_isSelectionMode)
            BlocBuilder<NotesBloc, NotesState>(
              builder: (context, state) {
                return IconButton(
                  icon: Icon(
                    state.isGridView ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                    color: navyColor.withValues(alpha: 0.5),
                  ),
                  onPressed: () => context.read<NotesBloc>().add(ToggleViewMode()),
                );
              },
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _deleteSelectedNotes,
            ),
        ],
      ),
      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          if (state.status == NotesStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          var displayNotes = state.notes;
          
          if (widget.filterTrash) {
            displayNotes = displayNotes.where((note) => note.isTrashed).toList();
          } else {
            // Sembunyikan catatan di sampah jika tidak sedang di mode Sampah
            displayNotes = displayNotes.where((note) => !note.isTrashed).toList();
            
            if (widget.filterArchive) {
              displayNotes = displayNotes.where((note) => note.isArchived).toList();
            } else {
              displayNotes = displayNotes.where((note) => !note.isArchived).toList();
            }

            if (widget.filterFavorite) {
              displayNotes = displayNotes.where((note) => note.isFavorite).toList();
            }
          }

          if (displayNotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!widget.filterTrash && !widget.filterArchive && !widget.filterFavorite)
                    Image.asset(
                      'assets/images/empty_notes.png',
                      width: 180,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey.shade300),
                    )
                  else
                    Icon(
                      widget.filterTrash ? Icons.delete_outline_rounded : (widget.filterArchive ? Icons.archive_outlined : Icons.star_outline), 
                      size: 64, 
                      color: Colors.grey.shade300
                    ),
                  const SizedBox(height: 24),
                  Text(
                    widget.filterTrash ? 'Sampah kosong' : (widget.filterArchive ? 'Belum ada catatan yang diarsipkan' : (widget.filterFavorite ? 'Belum ada catatan favorit' : 'Belum ada catatan')), 
                    style: TextStyle(color: navyColor, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                  if (!widget.filterTrash && !widget.filterArchive && !widget.filterFavorite) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Ayo mulai tulis ide cemerlangmu!',
                      style: TextStyle(color: navyColor.withValues(alpha: 0.5), fontSize: 14),
                    ),
                  ],
                ],
              ),
            );
          }

          if (state.isGridView) {
            return MasonryGridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 16,
              itemCount: displayNotes.length,
              itemBuilder: (context, index) {
                final note = displayNotes[index];
                return _buildNoteCard(note, state.categories, context);
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: state.notes.length,
            itemBuilder: (context, index) {
              final note = state.notes[index];
              return _buildNoteCard(note, state.categories, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(Note note, List<Category> categories, BuildContext context) {
    final isSelected = _selectedNoteIds.contains(note.id);
    final categoryName = _getCategoryName(note.categoryId, categories);
    final parsedDate = DateTime.tryParse(note.created) ?? DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(parsedDate.toLocal());

    String displayContent = note.contentText;
    if (displayContent.trim().startsWith('[') && displayContent.trim().endsWith(']')) {
      try {
        final decoded = jsonDecode(displayContent);
        final doc = quill.Document.fromJson(decoded);
        displayContent = doc.toPlainText().trim();
      } catch (_) {}
    }

    return GestureDetector(
      onLongPress: () {
        if (widget.filterTrash) {
          _showTrashOptions(context, note);
        } else {
          _toggleSelection(note.id);
        }
      },
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(note.id);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(
                note: note,
                userId: widget.userId,
                categories: categories,
              ),
            ),
          );
        }
      },
      onSecondaryTap: () {
        if (widget.filterTrash) {
          _showTrashOptions(context, note);
        } else {
          _showNoteOptions(context, note);
        }
      },
      child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? primaryColor : navyColor.withValues(alpha: 0.05),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      if (!isSelected)
                        BoxShadow(
                          color: navyColor.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isSelectionMode) ...[
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(note.id),
                            activeColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.title.isNotEmpty ? note.title : 'Tanpa Judul',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: navyColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: navyColor.withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(height: 6),
                               Text(
                                displayContent.isNotEmpty ? displayContent : 'Catatan kosong...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: navyColor.withValues(alpha: 0.6),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0EA5E9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  void _showNoteOptions(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ListTile(
                leading: Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: primaryColor),
                title: Text(note.isPinned ? 'Lepas Sematan' : 'Sematkan Catatan', style: TextStyle(color: navyColor, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.read<NotesBloc>().add(TogglePinEvent(note: note, userId: widget.userId));
                },
              ),
              ListTile(
                leading: Icon(note.isFavorite ? Icons.star_rounded : Icons.star_border_rounded, color: const Color(0xFFF59E0B)),
                title: Text(note.isFavorite ? 'Batal Favorit' : 'Tambahkan ke Favorit', style: TextStyle(color: navyColor, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.read<NotesBloc>().add(ToggleFavoriteEvent(note: note));
                },
              ),
              ListTile(
                leading: Icon(note.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, color: Colors.teal),
                title: Text(note.isArchived ? 'Batal Arsip' : 'Arsipkan Catatan', style: TextStyle(color: navyColor, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.read<NotesBloc>().add(ToggleArchiveEvent(note: note));
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Buang ke Sampah', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.read<NotesBloc>().add(MoveToTrashEvent(note: note));
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showTrashOptions(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                ListTile(
                  leading: Icon(Icons.restore, color: navyColor),
                  title: Text('Pulihkan Catatan', style: TextStyle(color: navyColor, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.read<NotesBloc>().add(RestoreNoteEvent(note: note));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: const Text('Hapus Permanen', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showPermanentDeleteConfirmation(context, note);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPermanentDeleteConfirmation(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Hapus Permanen?', style: TextStyle(color: navyColor, fontWeight: FontWeight.bold)),
          content: const Text('Catatan yang dihapus permanen tidak dapat dipulihkan kembali.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<NotesBloc>().add(PermanentDeleteNoteEvent(noteId: note.id, userId: widget.userId));
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
