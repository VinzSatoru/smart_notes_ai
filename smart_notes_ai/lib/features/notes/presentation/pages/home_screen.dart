import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/category.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        context.read<NotesBloc>().add(FetchCategoriesAndNotes(userId: authState.user.id));
      }
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Aplikasi'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNoteOptions(BuildContext context, Note note) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.id : '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                title: Text(note.isPinned ? 'Lepas Sematan' : 'Sematkan Catatan'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.read<NotesBloc>().add(TogglePinEvent(note: note, userId: userId));
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Catatan', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.read<NotesBloc>().add(DeleteNoteEvent(noteId: note.id, userId: userId));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddNoteOptions(BuildContext context, String userId, List<Category> categories) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Buat Catatan Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAddOption(
                      icon: Icons.edit_note,
                      label: 'Tulis Manual',
                      color: const Color(0xFF4F64F2),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteEditorScreen(
                              userId: userId,
                              categories: categories,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildAddOption(
                      icon: Icons.mic,
                      label: 'Rekam Suara',
                      color: const Color(0xFFFF6B6B),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur rekaman AI akan segera hadir!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userName = 'Pengguna';
    String userId = '';
    if (authState is Authenticated) {
      userName = authState.user.name;
      userId = authState.user.id;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Hai, $userName',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          BlocBuilder<NotesBloc, NotesState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  state.isGridView ? Icons.view_agenda_outlined : Icons.grid_view,
                  color: Colors.black87,
                ),
                onPressed: () {
                  context.read<NotesBloc>().add(ToggleViewMode());
                },
                tooltip: 'Ubah Tampilan',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.black87),
            onPressed: _showLogoutDialog,
            tooltip: 'Profil',
          ),
        ],
      ),
      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          if (state.status == NotesStatus.failure) {
            return Center(child: Text(state.errorMessage, style: const TextStyle(color: Colors.red)));
          }

          return Column(
            children: [
              // Category Tabs
              _buildCategoryTabs(context, state, userId),
              
              // Notes Content
              Expanded(
                child: state.status == NotesStatus.loading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F64F2)))
                    : state.notes.isEmpty
                        ? _buildEmptyState()
                        : _buildNotesList(context, state, userId),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4F64F2),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.mic),
        label: const Text(
          'Catat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          _showAddNoteOptions(context, userId, context.read<NotesBloc>().state.categories);
        },
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context, NotesState state, String userId) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildTab(
            title: 'Semua',
            isSelected: state.selectedCategoryId == 'all',
            onTap: () {
              context.read<NotesBloc>().add(FilterNotesByCategory(categoryId: 'all', userId: userId));
            },
          ),
          ...state.categories.map((category) {
            return _buildTab(
              title: category.name,
              isSelected: state.selectedCategoryId == category.id,
              onTap: () {
                context.read<NotesBloc>().add(FilterNotesByCategory(categoryId: category.id, userId: userId));
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTab({required String title, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F64F2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNotesList(BuildContext context, NotesState state, String userId) {
    if (state.isGridView) {
      // Tampilan Masonry Grid (Asimetris)
      return MasonryGridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: state.notes.length,
        itemBuilder: (context, index) {
          final note = state.notes[index];
          return NoteCard(
            note: note,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteEditorScreen(
                    note: note,
                    userId: userId,
                    categories: state.categories,
                  ),
                ),
              );
            },
            onLongPress: () => _showNoteOptions(context, note),
          );
        },
      );
    } else {
      // Tampilan ListView biasa
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.notes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final note = state.notes[index];
          return NoteCard(
            note: note,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteEditorScreen(
                    note: note,
                    userId: userId,
                    categories: state.categories,
                  ),
                ),
              );
            },
            onLongPress: () => _showNoteOptions(context, note),
          );
        },
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Kosong',
            style: TextStyle(
              fontSize: 20,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol Catat untuk membuat\ncatatan baru atau merekam suara.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, height: 1.5),
          ),
        ],
      ),
    );
  }
}
