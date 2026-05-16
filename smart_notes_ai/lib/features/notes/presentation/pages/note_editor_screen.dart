import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:intl/intl.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/category.dart';
import 'package:smart_notes_ai/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:smart_notes_ai/features/ai/presentation/bloc/ai_event.dart';
import 'package:smart_notes_ai/features/ai/presentation/bloc/ai_state.dart';

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
  
  // Theme state
  Color _currentBgColor = const Color(0xFFF8F9FF);
  PaperPattern _currentPattern = PaperPattern.none;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.contentText ?? '');
    
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
          ));
    } else {
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

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF1E293B);
    const primaryColor = Color(0xFF4F64F2);
    final String timeFormatted = DateFormat('HH.mm').format(DateTime.now());
    final String dayFormatted = 'Hari Ini';

    return BlocConsumer<AiBloc, AiState>(
      listener: (context, state) {
        if (state is AiSuccess) {
          final currentText = _contentController.text;
          _contentController.text = currentText.isEmpty ? state.text : '$currentText\n${state.text}';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transkripsi suara ditambahkan'), behavior: SnackBarBehavior.floating),
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
              IconButton(icon: const Icon(Icons.undo_rounded, color: Colors.grey), onPressed: () {}),
              IconButton(icon: const Icon(Icons.redo_rounded, color: Colors.grey), onPressed: () {}),
              IconButton(icon: const Icon(Icons.ios_share_rounded, color: navyColor, size: 22), onPressed: () {}),
              IconButton(icon: const Icon(Icons.more_vert_rounded, color: navyColor), onPressed: () {}),
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
                          ),
                          TextField(
                            controller: _contentController,
                            style: TextStyle(fontSize: 18, color: navyColor.withValues(alpha: 0.7), height: 1.6),
                            decoration: const InputDecoration(hintText: 'Catatan di sini', hintStyle: TextStyle(color: Colors.black26), border: InputBorder.none),
                            maxLines: null,
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
    bool isChecking = state is AiCheckingQuota;
    bool isTranscribing = state is AiTranscribing;

    if (isChecking || isTranscribing) {
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

    return AvatarGlow(
      animate: isRecording,
      glowColor: Colors.red,
      duration: const Duration(milliseconds: 2000),
      child: FloatingActionButton(
        heroTag: 'note_mic_fab',
        onPressed: () {
          if (isRecording) {
            context.read<AiBloc>().add(StopRecordingAndTranscribe());
          } else {
            context.read<AiBloc>().add(CheckQuotaAndStartRecording());
          }
        },
        backgroundColor: isRecording ? Colors.red : primaryColor,
        elevation: 4,
        child: Icon(
          isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Pilih Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...widget.categories.map((c) => ListTile(
              title: Text(c.name),
              onTap: () {
                setState(() => _selectedCategoryId = c.id);
                Navigator.pop(context);
              },
            )),
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
