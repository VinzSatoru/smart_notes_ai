import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/category.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note; // If null, it's a new note (always edit mode)
  final String userId;
  final List<Category> categories;

  const NoteEditorScreen({
    super.key,
    this.note,
    required this.userId,
    required this.categories,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _selectedCategoryId;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.note == null; // Auto-edit mode if new note
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.contentText ?? '');
    
    // Set initial category if editing
    if (widget.note != null && widget.note!.categoryId.isNotEmpty) {
      final exists = widget.categories.any((c) => c.id == widget.note!.categoryId);
      if (exists) {
        _selectedCategoryId = widget.note!.categoryId;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // If completely empty, just discard
    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.note == null) {
      // Add new note
      context.read<NotesBloc>().add(AddNoteEvent(
            userId: widget.userId,
            title: title.isEmpty ? 'Catatan Tanpa Judul' : title,
            contentText: content,
            categoryId: _selectedCategoryId ?? 'all',
          ));
    } else {
      // Update existing note
      context.read<NotesBloc>().add(UpdateNoteEvent(
            noteId: widget.note!.id,
            userId: widget.userId,
            title: title.isEmpty ? 'Catatan Tanpa Judul' : title,
            contentText: content,
            categoryId: _selectedCategoryId ?? 'all',
          ));
    }
    
    Navigator.pop(context);
  }

  void _deleteNote() {
    if (widget.note == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              context.read<NotesBloc>().add(DeleteNoteEvent(
                noteId: widget.note!.id,
                userId: widget.userId,
              ));
              Navigator.pop(context); // Kembali ke Home
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4F64F2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (widget.note != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteNote,
              tooltip: 'Hapus Catatan',
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black87),
              onPressed: _toggleEditMode,
              tooltip: 'Edit Catatan',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check, color: primaryColor),
              onPressed: _saveNote,
              tooltip: 'Simpan',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Dropdown (Only show in edit mode if categories exist)
              if (_isEditing && widget.categories.isNotEmpty) ...[
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Pilih Kategori'),
                    value: _selectedCategoryId,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    items: widget.categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Jika mode baca, dan ada kategori yang dipilih, tampilkan badge
              if (!_isEditing && _selectedCategoryId != null && _selectedCategoryId != 'all') ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => const Category(id: '', name: '')).name,
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Input/View Judul
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Hero(
                        tag: 'note_title_${widget.note?.id ?? 'new'}',
                        child: Material(
                          color: Colors.transparent,
                          child: TextField(
                            controller: _titleController,
                            readOnly: !_isEditing,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: _isEditing ? 'Judul Catatan' : '',
                              hintStyle: const TextStyle(color: Colors.black26),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Input/View Konten
                      Hero(
                        tag: 'note_content_${widget.note?.id ?? 'new'}',
                        child: Material(
                          color: Colors.transparent,
                          child: TextField(
                            controller: _contentController,
                            readOnly: !_isEditing,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.6, // Better line height for reading
                            ),
                            decoration: InputDecoration(
                              hintText: _isEditing ? 'Mulai mengetik...' : '',
                              hintStyle: const TextStyle(color: Colors.black26),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
