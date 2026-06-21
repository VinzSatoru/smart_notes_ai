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
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import 'package:smart_notes_ai/features/payment/presentation/pages/payment_method_screen.dart';

// Colors will be dynamic

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
  Color get primaryColor => Theme.of(context).primaryColor;
  Color get navyColor => Theme.of(context).colorScheme.onSurface;
  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get cardColor => Theme.of(context).cardTheme.color ?? Colors.white;
  Color get subtitleColor => Theme.of(context).colorScheme.onSurfaceVariant;
  late TextEditingController _titleController;
  late quill.QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  String? _selectedCategoryId;
  String? _summaryText;
  String? _translateText;
  String? _translateLang;

  Timer? _recordTimer;
  final ValueNotifier<int> _recordDuration = ValueNotifier<int>(0);

  late UndoHistoryController _undoController;

  // Theme state
  Color? _currentBgColor;
  PaperPattern _currentPattern = PaperPattern.none;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');

    quill.Document document;
    final initialContent = widget.note?.contentText ?? '';
    if (initialContent.trim().startsWith('[') &&
        initialContent.trim().endsWith(']')) {
      try {
        final decoded = jsonDecode(initialContent);
        document = quill.Document.fromJson(decoded);
      } catch (e) {
        document = quill.Document()..insert(0, initialContent);
      }
    } else {
      document = quill.Document()..insert(0, initialContent);
    }

    _quillController = quill.QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _undoController =
        UndoHistoryController(); // Used only for title now if needed, but we might remove it. Let's keep it for compatibility.
    _summaryText = widget.note?.aiSummary;
    _translateText = widget.note?.aiTranslation;

    if (widget.note != null && widget.note!.categoryId.isNotEmpty) {
      final exists = widget.categories.any(
        (c) => c.id == widget.note!.categoryId,
      );
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
    _recordTimer?.cancel();
    _recordDuration.dispose();
    _titleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _undoController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final contentPlainText = _quillController.document.toPlainText().trim();
    final contentJson = jsonEncode(
      _quillController.document.toDelta().toJson(),
    );

    if (title.isEmpty && contentPlainText.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.note == null) {
      context.read<NotesBloc>().add(
        AddNoteEvent(
          userId: widget.userId,
          title: title.isEmpty ? 'Catatan Tanpa Judul' : title,
          contentText: contentJson,
          categoryId: _selectedCategoryId ?? 'all',
          aiSummary: _summaryText,
          aiTranslation: _translateText,
        ),
      );
    } else {
      context.read<NotesBloc>().add(
        UpdateNoteEvent(
          noteId: widget.note!.id,
          userId: widget.userId,
          title: title.isEmpty ? 'Catatan Tanpa Judul' : title,
          contentText: contentJson,
          categoryId: _selectedCategoryId ?? 'all',
          aiSummary: _summaryText,
          aiTranslation: _translateText,
        ),
      );
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
            Text(
              'Limit Tercapai',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentMethodScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F64F2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Upgrade Pro',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareNote() {
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Catatan Tanpa Judul';
    final content = _quillController.document.toPlainText().trim();
    if (content.isEmpty && title == 'Catatan Tanpa Judul') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan masih kosong.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final shareText = '$title\n\n$content';
    Share.share(shareText);
  }

  void _showFormatToolbar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Format Teks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
              ),
              const SizedBox(height: 16),
              quill.QuillToolbar.simple(
                configurations: quill.QuillSimpleToolbarConfigurations(
                  controller: _quillController,
                  sharedConfigurations: const quill.QuillSharedConfigurations(
                    locale: Locale('id'),
                  ),
                  showUndo: false,
                  showRedo: false,
                  showFontFamily: false,
                  showFontSize: false,
                  showColorButton: false,
                  showBackgroundColorButton: false,
                  showSearchButton: false,
                  showSubscript: false,
                  showSuperscript: false,
                  showInlineCode: false,
                  showCodeBlock: false,
                  showClearFormat: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleChecklist() {
    final isChecked =
        _quillController.getSelectionStyle().containsKey(
          quill.Attribute.unchecked.key,
        ) ||
        _quillController.getSelectionStyle().containsKey(
          quill.Attribute.checked.key,
        );
    _quillController.formatSelection(
      isChecked
          ? quill.Attribute.clone(quill.Attribute.unchecked, null)
          : quill.Attribute.unchecked,
    );
  }

  void _toggleBulletList() {
    final isList = _quillController.getSelectionStyle().containsKey(
      quill.Attribute.ul.key,
    );
    _quillController.formatSelection(
      isList
          ? quill.Attribute.clone(quill.Attribute.ul, null)
          : quill.Attribute.ul,
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final index = _quillController.selection.baseOffset;
      final length = _quillController.selection.extentOffset - index;
      _quillController.replaceText(
        index,
        length,
        quill.BlockEmbed.image(pickedFile.path),
        null,
      );
    }
  }

  void _showNotSupported(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showMoreOptions() {
    if (widget.note == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simpan catatan terlebih dahulu untuk opsi tambahan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return BlocBuilder<NotesBloc, NotesState>(
          builder: (context, state) {
            final matchingNotes = state.notes.where(
              (n) => n.id == widget.note!.id,
            );
            final note = matchingNotes.isNotEmpty
                ? matchingNotes.first
                : widget.note!;

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        color: const Color(0xFF475569),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      note.isPinned ? 'Lepas Sematan' : 'Sematkan Catatan',
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      context.read<NotesBloc>().add(
                        TogglePinEvent(note: note, userId: widget.userId),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        note.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFF475569),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      note.isFavorite
                          ? 'Batal Favorit'
                          : 'Tambahkan ke Favorit',
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      context.read<NotesBloc>().add(
                        ToggleFavoriteEvent(note: note),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        note.isArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                        color: const Color(0xFF475569),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      note.isArchived ? 'Batal Arsip' : 'Arsipkan Catatan',
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      context.read<NotesBloc>().add(
                        ToggleArchiveEvent(note: note),
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFEF4444),
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Buang ke Sampah',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      Navigator.pop(this.context);
                      context.read<NotesBloc>().add(
                        MoveToTrashEvent(note: note),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Tema Kertas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPatternOption(
                        PaperPattern.none,
                        'Polos',
                        setModalState,
                      ),
                      _buildPatternOption(
                        PaperPattern.ruled,
                        'Garis',
                        setModalState,
                      ),
                      _buildPatternOption(
                        PaperPattern.grid,
                        'Kotak',
                        setModalState,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Pilih Warna',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children:
                          [
                                const Color(0xFFFFFFFF),
                                const Color(0xFFF8F9FF),
                                const Color(0xFFFDF8FF),
                                const Color(0xFFF8FFF9),
                                const Color(0xFFFFFBF0),
                                const Color(0xFFD7FBE1),
                                const Color(0xFFE5DEFF),
                              ]
                              .map(
                                (color) => GestureDetector(
                                  onTap: () {
                                    setModalState(
                                      () => _currentBgColor = color,
                                    );
                                    setState(() => _currentBgColor = color);
                                  },
                                  child: Container(
                                    width: 50,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: (_currentBgColor ?? backgroundColor) == color
                                            ? const Color(0xFF4F64F2)
                                            : Colors.grey.shade300,
                                        width: (_currentBgColor ?? backgroundColor) == color ? 3 : 1,
                                      ),
                                    ),
                                    child: (_currentBgColor ?? backgroundColor) == color
                                        ? const Icon(
                                            Icons.check,
                                            color: Color(0xFF4F64F2),
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                ),
                              )
                              .toList(),
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

  Widget _buildPatternOption(
    PaperPattern pattern,
    String label,
    Function setModalState,
  ) {
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
              color: isSelected
                  ? const Color(0xFF4F64F2).withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4F64F2)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              pattern == PaperPattern.none
                  ? Icons.crop_square
                  : (pattern == PaperPattern.ruled
                        ? Icons.reorder
                        : Icons.grid_4x4),
              color: isSelected ? const Color(0xFF4F64F2) : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFF4F64F2) : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  child: Text(
                    '🌐 Pilih Bahasa',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
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
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.read<AiBloc>().add(
                            ProcessTextRequested(
                              text: _quillController.document.toPlainText(),
                              action: 'translate:${lang['code']}',
                            ),
                          );
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

  void _showAiResultSheet(String title, String content, {String? actionLabel, VoidCallback? onAction}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.grey,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Text(
                          content,
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(
                              0xFF1E293B,
                            ).withValues(alpha: 0.8),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onAction();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F64F2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            actionLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
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
    final String timeFormatted = DateFormat('HH.mm').format(DateTime.now());
    final String dayFormatted = 'Hari Ini';
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AiBloc, AiState>(
      listener: (context, state) {
        if (state is AiRecording) {
          _recordTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
            _recordDuration.value++;
          });
        } else if (state is AiRecordingPaused) {
          _recordTimer?.cancel();
          _recordTimer = null;
        } else {
          _recordTimer?.cancel();
          _recordTimer = null;
          _recordDuration.value = 0;
        }

        if (state is AiSuccess) {
          if (state.action == 'transcribe') {
            final currentText = _quillController.document.toPlainText().trim();
            if (currentText.isEmpty) {
              _quillController.document.insert(0, state.text);
            } else {
              _quillController.document.insert(
                _quillController.document.length - 1,
                '\n${state.text}',
              );
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transkripsi suara ditambahkan'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state.action == 'summary') {
            setState(() {
              _summaryText = state.text;
            });
            _showAiResultSheet('Rangkuman AI', state.text);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rangkuman berhasil dibuat ✨'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state.action.startsWith('translate:')) {
            final targetLang = state.action.split(':')[1];
            setState(() {
              _translateLang = targetLang;
              _translateText = state.text;
            });
            _showAiResultSheet('Terjemahan ($targetLang)', state.text);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Terjemahan berhasil dibuat ✨'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else if (state is AiProcessingText) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Memproses teks...'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        } else if (state is AiFailure) {
          if (state.isQuotaExceeded) {
            _showUpgradeDialog(context, state.message);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      builder: (context, aiState) {
        final bgColor = _currentBgColor ?? backgroundColor;
        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              // Background Pattern
              if (_currentPattern != PaperPattern.none)
                Positioned.fill(
                  child: CustomPaint(
                    painter: PaperPainter(
                      pattern: _currentPattern,
                      color: navyColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              // Main Scrollable Content
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Custom Premium Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios_new_rounded, color: navyColor),
                            onPressed: _saveNote,
                          ),
                          Row(
                            children: [
                              ListenableBuilder(
                                listenable: _quillController,
                                builder: (context, child) {
                                  return Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.undo_rounded, size: 22, color: _quillController.hasUndo ? navyColor : Colors.grey),
                                        onPressed: _quillController.hasUndo ? () => _quillController.undo() : null,
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.redo_rounded, size: 22, color: _quillController.hasRedo ? navyColor : Colors.grey),
                                        onPressed: _quillController.hasRedo ? () => _quillController.redo() : null,
                                      ),
                                    ],
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.more_vert_rounded, color: navyColor),
                                onPressed: _showMoreOptions,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Editor Content
                    // Editor Content
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                // Metadata (Category & Date)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showCategoryPicker(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.folder_outlined, size: 14, color: primaryColor),
                                            const SizedBox(width: 6),
                                            Text(
                                              _selectedCategoryId == null || _selectedCategoryId == 'all'
                                                  ? 'Tanpa Kategori'
                                                  : widget.categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => widget.categories.first).name,
                                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$dayFormatted, $timeFormatted',
                                      style: TextStyle(
                                        color: navyColor.withValues(alpha: 0.4),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Title
                                TextField(
                                  controller: _titleController,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: navyColor,
                                    height: 1.2,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Judul Catatan',
                                    hintStyle: TextStyle(color: Colors.black26),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  maxLines: null,
                                  contextMenuBuilder: (context, editableTextState) {
                                    return AdaptiveTextSelectionToolbar.editableText(
                                      editableTextState: editableTextState,
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                // Quill Editor
                                quill.QuillEditor.basic(
                                  configurations: quill.QuillEditorConfigurations(
                                    controller: _quillController,
                                    placeholder: 'Mulai menulis...',
                                    padding: EdgeInsets.zero,
                                    scrollable: false,
                                    expands: false,
                                    autoFocus: false,
                                  ),
                                  focusNode: _editorFocusNode,
                                ),
                                const SizedBox(height: 32),
                              ]),
                            ),
                          ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            fillOverscroll: true,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // AI Results / Action Cards
                                  ListenableBuilder(
                                    listenable: _quillController,
                                    builder: (context, child) {
                                      final isEmpty = _quillController.document.toPlainText().trim().isEmpty;
                                      final hasSummary = _summaryText != null && _summaryText!.isNotEmpty;
                                      final hasTranslate = _translateText != null && _translateText!.isNotEmpty;
                                      return Opacity(
                                        opacity: isEmpty ? 0.4 : 1.0,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: isDark 
                                                      ? [const Color(0xFF3B285E), const Color(0xFF2A1C40)]
                                                      : const [Color(0xFFF3E8FF), Color(0xFFE0E7FF)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF4F64F2).withValues(alpha: 0.15),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(20),
                                                  onTap: () {
                                                    if (hasSummary) {
                                                      _showAiResultSheet(
                                                        'Rangkuman AI', 
                                                        _summaryText!,
                                                        actionLabel: 'Rangkum Ulang',
                                                        onAction: () {
                                                          if (isEmpty) {
                                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan masih kosong.'), behavior: SnackBarBehavior.floating));
                                                            return;
                                                          }
                                                          context.read<AiBloc>().add(
                                                            ProcessTextRequested(
                                                              text: _quillController.document.toPlainText(),
                                                              action: 'summary',
                                                            ),
                                                          );
                                                        }
                                                      );
                                                    } else {
                                                      if (isEmpty) {
                                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan masih kosong.'), behavior: SnackBarBehavior.floating));
                                                        return;
                                                      }
                                                      context.read<AiBloc>().add(
                                                        ProcessTextRequested(
                                                          text: _quillController.document.toPlainText(),
                                                          action: 'summary',
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(20),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(12),
                                                          decoration: const BoxDecoration(
                                                            color: Colors.white,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6)),
                                                        ),
                                                        const SizedBox(width: 16),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                hasSummary ? 'Rangkuman AI Tersedia' : 'Rangkuman AI',
                                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: navyColor),
                                                              ),
                                                              Text(
                                                                hasSummary ? 'Ketuk untuk melihat hasil rangkuman.' : 'Belum ada rangkuman catatan. Ketuk untuk merangkum.',
                                                                style: TextStyle(fontSize: 13, color: subtitleColor),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Icon(Icons.arrow_forward_ios_rounded, size: 16, color: subtitleColor.withValues(alpha: 0.5)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: isDark 
                                                      ? [const Color(0xFF1A3E2C), const Color(0xFF132B1F)]
                                                      : const [Color(0xFFDCFCE7), Color(0xFFD1FAE5)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green.withValues(alpha: 0.15),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(20),
                                                  onTap: () {
                                                    if (hasTranslate) {
                                                      _showAiResultSheet(
                                                        'Terjemahan (${_translateLang ?? ''})', 
                                                        _translateText!,
                                                        actionLabel: 'Ganti Bahasa',
                                                        onAction: () {
                                                          if (isEmpty) {
                                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan masih kosong.'), behavior: SnackBarBehavior.floating));
                                                            return;
                                                          }
                                                          _showLanguagePicker();
                                                        }
                                                      );
                                                    } else {
                                                      if (isEmpty) {
                                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan masih kosong.'), behavior: SnackBarBehavior.floating));
                                                        return;
                                                      }
                                                      _showLanguagePicker();
                                                    }
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(20),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(12),
                                                          decoration: const BoxDecoration(
                                                            color: Colors.white,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(Icons.language_rounded, color: Colors.green),
                                                        ),
                                                        const SizedBox(width: 16),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                hasTranslate ? 'Terjemahan ${_translateLang ?? 'Tersedia'}' : 'Terjemahan',
                                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: navyColor),
                                                              ),
                                                              Text(
                                                                hasTranslate ? 'Ketuk untuk melihat hasil terjemahan.' : 'Belum ada terjemahan catatan. Ketuk untuk menerjemahkan.',
                                                                style: TextStyle(fontSize: 13, color: subtitleColor),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Icon(Icons.arrow_forward_ios_rounded, size: 16, color: subtitleColor.withValues(alpha: 0.5)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Dock (Glassmorphism Toolbar + Mic)
              Positioned(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? MediaQuery.of(context).viewInsets.bottom + 10 : 30,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: cardColor.withValues(alpha: 0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Format Tools
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ListenableBuilder(
                                listenable: _quillController,
                                builder: (context, child) {
                                  return Row(
                                    children: [
                                      Container(width: 1, height: 24, color: Colors.transparent, margin: const EdgeInsets.symmetric(horizontal: 4)),
                                      IconButton(icon: Icon(Icons.text_fields_rounded, size: 22, color: navyColor), onPressed: _showFormatToolbar),
                                      IconButton(icon: Icon(Icons.check_box_outlined, size: 22, color: navyColor), onPressed: _toggleChecklist),
                                      IconButton(icon: Icon(Icons.format_list_bulleted_rounded, size: 22, color: navyColor), onPressed: _toggleBulletList),
                                      IconButton(icon: Icon(Icons.image_outlined, size: 22, color: navyColor), onPressed: _pickImage),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          // Mic Button
                          _buildFloatingMicButton(aiState, primaryColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
          child: CircularProgressIndicator(
            color: Color(0xFF4F64F2),
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRecording || isPaused) ...[
          ValueListenableBuilder<int>(
            valueListenable: _recordDuration,
            builder: (context, duration, child) {
              final minutes = (duration ~/ 60).toString().padLeft(2, '0');
              final seconds = (duration % 60).toString().padLeft(2, '0');
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$minutes:$seconds',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
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
            backgroundColor: isRecording
                ? Colors.red
                : (isPaused ? Colors.orange : primaryColor),
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

  Widget _buildToolbarIcon(
    IconData icon, {
    String? label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF1E293B).withValues(alpha: 0.6),
            size: 24,
          ),
          if (label != null)
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return BlocBuilder<NotesBloc, NotesState>(
          builder: (context, state) {
            // Gunakan state.categories jika tersedia, jika tidak gunakan widget.categories
            final currentCategories = state.categories.isNotEmpty
                ? state.categories
                : widget.categories;

            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Pilih Kategori',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF4F64F2),
                  ),
                  title: const Text(
                    'Tambah Kategori',
                    style: TextStyle(
                      color: Color(0xFF4F64F2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showAddCategoryDialog();
                  },
                ),
                const Divider(),
                ...currentCategories.map(
                  (c) => ListTile(
                    title: Text(c.name),
                    trailing: _selectedCategoryId == c.id
                        ? const Icon(Icons.check, color: Color(0xFF4F64F2))
                        : null,
                    onTap: () {
                      setState(() => _selectedCategoryId = c.id);
                      Navigator.pop(bottomSheetContext);
                    },
                  ),
                ),
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
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Kategori Baru',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: categoryController,
            decoration: InputDecoration(
              hintText: 'Nama kategori (mis: Ide Bisnis)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF4F64F2),
                  width: 2,
                ),
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
                  context.read<NotesBloc>().add(
                    AddCategoryEvent(userId: widget.userId, name: name),
                  );
                  Navigator.pop(dialogContext);
                  // Optionally, we could try to auto-select it once it's created, but that might be complex
                  // as it requires waiting for the state to update.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kategori "$name" ditambahkan!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F64F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
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
