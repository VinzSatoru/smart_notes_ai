import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/category.dart';
import 'note_editor_screen.dart';

class AllNotesManagementScreen extends StatefulWidget {
  final String userId;
  const AllNotesManagementScreen({super.key, required this.userId});

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
      backgroundColor: const Color(0xFFFBFBFD),
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
          _isSelectionMode ? '${_selectedNoteIds.length} Terpilih' : 'Manajemen Catatan',
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

          if (state.notes.isEmpty) {
            return Center(
              child: Text(
                'Belum ada catatan',
                style: TextStyle(color: navyColor.withValues(alpha: 0.5), fontSize: 16),
              ),
            );
          }

          if (state.isGridView) {
            return MasonryGridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: state.notes.length,
              itemBuilder: (context, index) {
                final note = state.notes[index];
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

    return GestureDetector(
      onLongPress: () => _toggleSelection(note.id),
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
                                note.contentText.isNotEmpty ? note.contentText : 'Catatan kosong...',
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
}
