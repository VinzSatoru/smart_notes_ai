import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:intl/intl.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/category.dart';
import 'package:smart_notes_ai/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:smart_notes_ai/features/ai/presentation/bloc/ai_event.dart';
import 'package:smart_notes_ai/features/ai/presentation/bloc/ai_state.dart';
import 'package:share_plus/share_plus.dart';

enum PaperPattern { none, ruled, grid }

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final String userId;
  final List<Category> categories;
  final bool autoStartRecording;

  const NoteEditorScreen({
    super.key,
    this.note,
    required this.userId,
    required this.categories,
    this.autoStartRecording = false,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _selectedCategoryId;
  String? _summaryText;
  String? _translateText;
  String? _translateLang;
  late UndoHistoryController _undoController;
  
  // Theme state
  Color _currentBgColor = const Color(0xFFF8F9FF);
  PaperPattern _currentPattern = PaperPattern.none;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.contentText ?? '');
    _undoController = UndoHistoryController();
    _summaryText = widget.note?.aiSummary;
    _translateText = widget.note?.aiTranslation;
    
    if (widget.note != null && widget.note!.categoryId.isNotEmpty) {
      final exists = widget.categories.any((c) => c.id == widget.note!.categoryId);
      if (exists) {
        _selectedCategoryId = widget.note!.categoryId;
      }
    }

    if (widget.autoStartRecording) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AiBloc>().add(CheckQuotaAndStartRecording());
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _undoController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.note == null) {
      context.read<NotesBloc>().add(AddNoteEvent(
            userId: widget.userId,
            title: title.isEmpty ? 'Catatan Tanpa Judul' : title,
            contentText: content,
            categoryId: _selectedCategoryId ?? 'all',
            aiSummary: _summaryText,
            aiTranslation: _translateText,
          ));
    } else {
      context.read<NotesBloc>().add(UpdateNoteEvent(
            noteId: widget.note!.id,
            userId: widget.userId,
            title: title.isEmpty ? 'Catatan Tanpa Judul' : title,
            contentText: content,
            categoryId: _selectedCategoryId ?? 'all',
            aiSummary: _summaryText,
            aiTranslation: _translateText,
          ));
    }
    
    Navigator.pop(context);
  }

  void _showUpgradeDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Color(0xFF4F64F2)),
            SizedBox(width: 10),
            Text('Limit Tercapai', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur Premium akan segera hadir!'), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F64F2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Upgrade Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _shareNote() {
    final title = _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Catatan Tanpa Judul';
    final content = _contentController.text.trim();
    if (content.isEmpty && title == 'Catatan Tanpa Judul') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan masih kosong.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    
    final shareText = '$title\n\n$content';
    Share.share(shareText);
  }

  void _showMoreOptions() {
    if (widget.note == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simpan catatan terlebih dahulu untuk opsi tambahan.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomSheetContext) {
        return BlocBuilder<NotesBloc, NotesState>(
          builder: (context, state) {
            final matchingNotes = state.notes.where((n) => n.id == widget.note!.id);
            final note = matchingNotes.isNotEmpty ? matchingNotes.first : widget.note!;
            
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  ListTile(
                    leading: Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: const Color(0xFF4F64F2)),
                    title: Text(note.isPinned ? 'Lepas Sematan' : 'Sematkan Catatan', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                    onTap: () {
                      context.read<NotesBloc>().add(TogglePinEvent(note: note, userId: widget.userId));
                    },
                  ),
                  ListTile(
                    leading: Icon(note.isFavorite ? Icons.star_rounded : Icons.star_border_rounded, color: const Color(0xFFF59E0B)),
                    title: Text(note.isFavorite ? 'Batal Favorit' : 'Tambahkan ke Favorit', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                    onTap: () {
                      context.read<NotesBloc>().add(ToggleFavoriteEvent(note: note));
                    },
                  ),
                  ListTile(
                    leading: Icon(note.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, color: Colors.teal),
                    title: Text(note.isArchived ? 'Batal Arsip' : 'Arsipkan Catatan', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                    onTap: () {
                      context.read<NotesBloc>().add(ToggleArchiveEvent(note: note));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    title: const Text('Buang ke Sampah', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      Navigator.pop(this.context);
                      context.read<NotesBloc>().add(MoveToTrashEvent(note: note));
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Tema Kertas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPatternOption(PaperPattern.none, 'Polos', setModalState),
                      _buildPatternOption(PaperPattern.ruled, 'Garis', setModalState),
                      _buildPatternOption(PaperPattern.grid, 'Kotak', setModalState),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text('Pilih Warna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        const Color(0xFFFFFFFF),
                        const Color(0xFFF8F9FF),
                        const Color(0xFFFDF8FF),
                        const Color(0xFFF8FFF9),
                        const Color(0xFFFFFBF0),
                        const Color(0xFFD7FBE1),
                        const Color(0xFFE5DEFF),
                      ].map((color) => GestureDetector(
                        onTap: () {
                          setModalState(() => _currentBgColor = color);
                          setState(() => _currentBgColor = color);
                        },
                        child: Container(
                          width: 50,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _currentBgColor == color ? const Color(0xFF4F64F2) : Colors.grey.shade300,
                              width: _currentBgColor == color ? 3 : 1,
                            ),
                          ),
                          child: _currentBgColor == color ? const Icon(Icons.check, color: Color(0xFF4F64F2), size: 20) : null,
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPatternOption(PaperPattern pattern, String label, Function setModalState) {
    bool isSelected = _currentPattern == pattern;
    return GestureDetector(
      onTap: () {
        setModalState(() => _currentPattern = pattern);
        setState(() => _currentPattern = pattern);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4F64F2).withValues(alpha: 0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? const Color(0xFF4F64F2) : Colors.transparent, width: 2),
            ),
            child: Icon(
              pattern == PaperPattern.none ? Icons.crop_square : (pattern == PaperPattern.ruled ? Icons.reorder : Icons.grid_4x4),
              color: isSelected ? const Color(0xFF4F64F2) : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: isSelected ? const Color(0xFF4F64F2) : Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showMagicAiSheet() {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan masih kosong.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('✨ Magic AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE5DEFF), child: Icon(Icons.summarize_rounded, color: Color(0xFF4F64F2))),
                  title: const Text('Rangkum Catatan', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Maks. 5x sehari', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<AiBloc>().add(ProcessTextRequested(
                      text: _contentController.text,
                      action: 'summary',
                    ));
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFD7FBE1), child: Icon(Icons.language_rounded, color: Colors.green)),
                  title: const Text('Terjemahkan ke...', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Gratis tanpa batas', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(context); // Tutup sheet pertama
                    _showLanguagePicker();  // Buka opsi bahasa
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguagePicker() {
    final List<Map<String, String>> languages = [
      {'name': 'English', 'code': 'English'},
      {'name': 'Indonesia', 'code': 'Indonesian'},
      {'name': 'Jepang', 'code': 'Japanese'},
      {'name': 'Korea', 'code': 'Korean'},
      {'name': 'Arab', 'code': 'Arabic'},
      {'name': 'Spanyol', 'code': 'Spanish'},
      {'name': 'Prancis', 'code': 'French'},
      {'name': 'Jerman', 'code': 'German'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('🌐 Pilih Bahasa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: languages.length,
                    itemBuilder: (context, index) {
                      final lang = languages[index];
                      return ListTile(
                        title: Text(lang['name']!),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        onTap: () {
                          Navigator.pop(context);
                          context.read<AiBloc>().add(ProcessTextRequested(
                            text: _contentController.text,
                            action: 'translate:${lang['code']}',
                          ));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAiResultSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Text(
                          content,
                          style: TextStyle(fontSize: 16, color: const Color(0xFF1E293B).withValues(alpha: 0.8), height: 1.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF1E293B);
    const primaryColor = Color(0xFF4F64F2);
    final String timeFormatted = DateFormat('HH.mm').format(DateTime.now());
    final String dayFormatted = 'Hari Ini';

    return BlocConsumer<AiBloc, AiState>(
      listener: (context, state) {
        if (state is AiSuccess) {
          if (state.action == 'transcribe') {
            final currentText = _contentController.text;
            _contentController.text = currentText.isEmpty ? state.text : '$currentText\n${state.text}';
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transkripsi suara ditambahkan'), behavior: SnackBarBehavior.floating),
            );
          } else if (state.action == 'summary') {
            setState(() {
              _summaryText = state.text;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rangkuman berhasil dibuat ✨'), behavior: SnackBarBehavior.floating),
            );
          } else if (state.action.startsWith('translate:')) {
            setState(() {
              _translateLang = state.action.split(':')[1];
              _translateText = state.text;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Terjemahan berhasil dibuat ✨'), behavior: SnackBarBehavior.floating),
            );
          }
        } else if (state is AiProcessingText) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✨ Memproses teks...'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
          );
        } else if (state is AiFailure) {
          if (state.isQuotaExceeded) {
            _showUpgradeDialog(context, state.message);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
            );
          }
        }
      },
      builder: (context, aiState) {
        return Scaffold(
          backgroundColor: _currentBgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.check_rounded, color: navyColor, size: 28),
              onPressed: _saveNote,
            ),
            actions: [
              IconButton(icon: const Icon(Icons.auto_awesome, color: Color(0xFF4F64F2)), onPressed: _showMagicAiSheet),
              ValueListenableBuilder<UndoHistoryValue>(
                valueListenable: _undoController,
                builder: (context, value, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.undo_rounded, color: value.canUndo ? navyColor : Colors.grey),
                        onPressed: value.canUndo ? () => _undoController.undo() : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.redo_rounded, color: value.canRedo ? navyColor : Colors.grey),
                        onPressed: value.canRedo ? () => _undoController.redo() : null,
                      ),
                    ],
                  );
                },
              ),
              IconButton(icon: const Icon(Icons.ios_share_rounded, color: navyColor, size: 22), onPressed: _shareNote),
              IconButton(icon: const Icon(Icons.more_vert_rounded, color: navyColor), onPressed: _showMoreOptions),
            ],
          ),
          body: Stack(
            children: [
              if (_currentPattern != PaperPattern.none)
                Positioned.fill(
                  child: CustomPaint(
                    painter: PaperPainter(pattern: _currentPattern, color: navyColor.withValues(alpha: 0.1)),
                  ),
                ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$dayFormatted, $timeFormatted', style: TextStyle(color: navyColor.withValues(alpha: 0.4), fontWeight: FontWeight.w500)),
                        GestureDetector(
                          onTap: () => _showCategoryPicker(),
                          child: Row(
                            children: [
                              Icon(Icons.book_outlined, size: 16, color: navyColor.withValues(alpha: 0.6)),
                              const SizedBox(width: 8),
                              Text(
                                _selectedCategoryId == null || _selectedCategoryId == 'all' 
                                  ? 'Tanpa Kategori' 
                                  : widget.categories.firstWhere((c) => c.id == _selectedCategoryId).name,
                                style: TextStyle(color: navyColor.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
                              ),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: navyColor.withValues(alpha: 0.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _titleController,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: navyColor),
                            decoration: const InputDecoration(hintText: 'Judul', hintStyle: TextStyle(color: Colors.black26), border: InputBorder.none),
                            maxLines: null,
                            contextMenuBuilder: (context, editableTextState) {
                              return AdaptiveTextSelectionToolbar.editableText(
                                editableTextState: editableTextState,
                              );
                            },
                          ),
                          TextField(
                            controller: _contentController,
                            undoController: _undoController,
                            style: TextStyle(fontSize: 18, color: navyColor.withValues(alpha: 0.7), height: 1.6),
                            decoration: const InputDecoration(hintText: 'Catatan di sini', hintStyle: TextStyle(color: Colors.black26), border: InputBorder.none),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            contextMenuBuilder: (context, editableTextState) {
                              return AdaptiveTextSelectionToolbar.editableText(
                                editableTextState: editableTextState,
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          if (_summaryText != null || _translateText != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_summaryText != null)
                                    ElevatedButton.icon(
                                      onPressed: () => _showAiResultSheet('Rangkuman AI', _summaryText!),
                                      icon: const Icon(Icons.summarize_rounded, color: Color(0xFF4F64F2)),
                                      label: const Text('Lihat Rangkuman', style: TextStyle(color: Color(0xFF4F64F2))),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4F64F2).withValues(alpha: 0.1),
                                        elevation: 0,
                                        alignment: Alignment.centerLeft,
                                      ),
                                    ),
                                  if (_summaryText != null && _translateText != null) const SizedBox(height: 12),
                                  if (_translateText != null)
                                    ElevatedButton.icon(
                                      onPressed: () => _showAiResultSheet('Terjemahan (${_translateLang ?? 'B. Lain'})', _translateText!),
                                      icon: const Icon(Icons.language_rounded, color: Colors.green),
                                      label: const Text('Lihat Terjemahan', style: TextStyle(color: Colors.green)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                                        elevation: 0,
                                        alignment: Alignment.centerLeft,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              Positioned(
                bottom: 20,
                right: 24,
                child: _buildFloatingMicButton(aiState, primaryColor),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 10, top: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolbarIcon(Icons.text_fields_rounded, label: 'Aa'),
                _buildToolbarIcon(Icons.check_box_outlined),
                _buildToolbarIcon(Icons.brush_rounded),
                _buildToolbarIcon(Icons.image_outlined),
                _buildToolbarIcon(Icons.emoji_emotions_outlined),
                _buildToolbarIcon(Icons.grid_4x4_rounded, onTap: _showThemePicker),
                _buildToolbarIcon(Icons.list_rounded),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingMicButton(AiState state, Color primaryColor) {
    bool isRecording = state is AiRecording;
    bool isPaused = state is AiRecordingPaused;
    bool isChecking = state is AiCheckingQuota;
    bool isTranscribing = state is AiTranscribing;
    bool isProcessingText = state is AiProcessingText;

    if (isChecking || isTranscribing || isProcessingText) {
      return FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: Color(0xFF4F64F2), strokeWidth: 2),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRecording || isPaused) ...[
          FloatingActionButton.small(
            heroTag: 'note_stop_fab',
            onPressed: () {
              context.read<AiBloc>().add(StopRecordingAndTranscribe());
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.stop_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
        ],
        AvatarGlow(
          animate: isRecording,
          glowColor: Colors.red,
          duration: const Duration(milliseconds: 2000),
          child: FloatingActionButton(
            heroTag: 'note_mic_fab',
            onPressed: () {
              if (isRecording) {
                context.read<AiBloc>().add(PauseRecording());
              } else if (isPaused) {
                context.read<AiBloc>().add(ResumeRecording());
              } else {
                context.read<AiBloc>().add(CheckQuotaAndStartRecording());
              }
            },
            backgroundColor: isRecording ? Colors.red : (isPaused ? Colors.orange : primaryColor),
            elevation: 4,
            child: Icon(
              isRecording ? Icons.pause_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarIcon(IconData icon, {String? label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF1E293B).withValues(alpha: 0.6), size: 24),
          if (label != null) Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomSheetContext) {
        return BlocBuilder<NotesBloc, NotesState>(
          builder: (context, state) {
            // Gunakan state.categories jika tersedia, jika tidak gunakan widget.categories
            final currentCategories = state.categories.isNotEmpty ? state.categories : widget.categories;
            
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Pilih Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: Color(0xFF4F64F2)),
                  title: const Text('Tambah Kategori', style: TextStyle(color: Color(0xFF4F64F2), fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showAddCategoryDialog();
                  },
                ),
                const Divider(),
                ...currentCategories.map((c) => ListTile(
                  title: Text(c.name),
                  trailing: _selectedCategoryId == c.id ? const Icon(Icons.check, color: Color(0xFF4F64F2)) : null,
                  onTap: () {
                    setState(() => _selectedCategoryId = c.id);
                    Navigator.pop(bottomSheetContext);
                  },
                )),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController categoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Kategori Baru', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: categoryController,
            decoration: InputDecoration(
              hintText: 'Nama kategori (mis: Ide Bisnis)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4F64F2), width: 2),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = categoryController.text.trim();
                if (name.isNotEmpty) {
                  context.read<NotesBloc>().add(AddCategoryEvent(userId: widget.userId, name: name));
                  Navigator.pop(dialogContext);
                  // Optionally, we could try to auto-select it once it's created, but that might be complex
                  // as it requires waiting for the state to update.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kategori "$name" ditambahkan!'), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F64F2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class PaperPainter extends CustomPainter {
  final PaperPattern pattern;
  final Color color;

  PaperPainter({required this.pattern, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    if (pattern == PaperPattern.ruled) {
      for (double i = 50; i < size.height; i += 30) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
      }
    } else if (pattern == PaperPattern.grid) {
      for (double i = 0; i < size.width; i += 30) {
        canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
      }
      for (double i = 0; i < size.height; i += 30) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
