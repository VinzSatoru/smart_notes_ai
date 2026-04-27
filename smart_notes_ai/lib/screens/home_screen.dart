import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/auth_provider.dart';
import '../providers/note_provider.dart';
import '../widgets/note_card.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ambil data catatan & kategori saat halaman dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final noteProvider = Provider.of<NoteProvider>(context, listen: false);
      noteProvider.fetchCategories();
      noteProvider.fetchNotes();
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
              Provider.of<AuthProvider>(context, listen: false).logout();
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

  void _showNoteOptions(BuildContext context, note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isPinned = note.getBoolValue('is_pinned');
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                title: Text(isPinned ? 'Lepas Sematan' : 'Sematkan Catatan'),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<NoteProvider>(context, listen: false).togglePin(note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Catatan', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<NoteProvider>(context, listen: false).deleteNote(note.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final noteProvider = Provider.of<NoteProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Hai, ${user?.getStringValue('name') ?? 'Pengguna'}',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              noteProvider.isGridView ? Icons.view_agenda_outlined : Icons.grid_view,
              color: Colors.black87,
            ),
            onPressed: noteProvider.toggleViewMode,
            tooltip: 'Ubah Tampilan',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.black87),
            onPressed: _showLogoutDialog,
            tooltip: 'Profil',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Tabs
          _buildCategoryTabs(noteProvider),
          
          // Notes Content
          Expanded(
            child: noteProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : noteProvider.notes.isEmpty
                    ? _buildEmptyState()
                    : _buildNotesList(noteProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.mic),
        label: const Text(
          'Catat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          // TODO: Navigasi ke Note Editor / Rekam Suara
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur rekaman suara akan segera hadir!')),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs(NoteProvider noteProvider) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildTab(
            title: 'Semua',
            isSelected: noteProvider.selectedCategoryId == 'all',
            onTap: () => noteProvider.setCategory('all'),
          ),
          ...noteProvider.categories.map((category) {
            return _buildTab(
              title: category.getStringValue('name'),
              isSelected: noteProvider.selectedCategoryId == category.id,
              onTap: () => noteProvider.setCategory(category.id),
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
          color: isSelected ? Colors.teal : Colors.grey.shade100,
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

  Widget _buildNotesList(NoteProvider noteProvider) {
    if (noteProvider.isGridView) {
      // Tampilan Masonry Grid (Asimetris)
      return MasonryGridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: noteProvider.notes.length,
        itemBuilder: (context, index) {
          final note = noteProvider.notes[index];
          return NoteCard(
            note: note,
            onTap: () {
              // TODO: Buka Editor
            },
            onLongPress: () => _showNoteOptions(context, note),
          );
        },
      );
    } else {
      // Tampilan ListView biasa
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: noteProvider.notes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final note = noteProvider.notes[index];
          return NoteCard(
            note: note,
            onTap: () {
              // TODO: Buka Editor
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
            'Belum ada catatan',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol Catat untuk mulai\nmerekam suara atau mengetik.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
