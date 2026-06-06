import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:animate_do/animate_do.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';
import 'calendar_screen.dart';
import 'all_notes_management_screen.dart';
import 'settings_screen.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/category.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:smart_notes_ai/features/payment/presentation/pages/payment_method_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color primaryColor = const Color(0xFF4F64F2);
  final Color navyColor = const Color(0xFF1E293B);
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar Aplikasi', style: TextStyle(color: navyColor, fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari SmartNotes AI?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                  context.read<NotesBloc>().add(TogglePinEvent(note: note, userId: userId));
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

  void _showAddNoteOptions(BuildContext context, String userId, List<Category> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 30),
              Text(
                'Buat Catatan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: navyColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih metode untuk menangkap ide Anda',
                style: TextStyle(fontSize: 14, color: navyColor.withValues(alpha: 0.4), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              _buildAddOptionCard(
                icon: Icons.edit_note_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Tulis Manual',
                subtitle: 'Ketik ide Anda secara terstruktur',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteEditorScreen(userId: userId, categories: categories),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildAddOptionCard(
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Voice AI',
                subtitle: 'Rekam suara dan biarkan AI merangkum',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteEditorScreen(
                        userId: userId,
                        categories: categories,
                        autoStartRecording: true,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: navyColor.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyColor)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: navyColor.withValues(alpha: 0.4))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: navyColor.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userName = 'Pengguna';
    String userId = '';
    bool isPremium = false;
    if (authState is Authenticated) {
      userName = authState.user.name.split(' ')[0];
      userId = authState.user.id;
      isPremium = authState.user.isPremium;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      drawer: _buildDrawer(userName, userId, isPremium),
      body: SafeArea(
        child: BlocBuilder<NotesBloc, NotesState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar (Hamburger + Search + Calendar)
                _buildHeaderBar(userId),
                
                // Category Pills + Grid Toggle
                _buildCategoryRow(context, state, userId),
                
                // Notes Content
                Expanded(
                  child: state.status == NotesStatus.loading
                      ? Center(child: CircularProgressIndicator(color: primaryColor))
                      : state.notes.isEmpty
                          ? _buildEmptyState()
                          : _buildNotesList(context, state, userId),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FadeInUp(
        duration: const Duration(milliseconds: 800),
        child: AvatarGlow(
          glowColor: primaryColor,
          duration: const Duration(milliseconds: 2000),
          repeat: true,
          child: GestureDetector(
            onTap: () => _showAddNoteOptions(context, userId, context.read<NotesBloc>().state.categories),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F64F2), Color(0xFF3B4CEB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 36),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBar(String userId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.menu_rounded, color: navyColor, size: 28),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: navyColor.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  context.read<NotesBloc>().add(SearchNotes(query: value, userId: userId));
                },
                decoration: InputDecoration(
                  hintText: 'Cari catatan...',
                  hintStyle: TextStyle(color: navyColor.withValues(alpha: 0.3), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: navyColor.withValues(alpha: 0.4), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.calendar_month_rounded, color: navyColor, size: 26),
            onPressed: () {
              // Muat semua catatan agar filter lokal kalender berfungsi maksimal
              context.read<NotesBloc>().add(FilterNotesByCategory(categoryId: 'all', userId: userId));
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarScreen(userId: userId)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, NotesState state, String userId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab(
                    title: 'Semua',
                    isSelected: state.selectedCategoryId == 'all',
                    onTap: () => context.read<NotesBloc>().add(FilterNotesByCategory(categoryId: 'all', userId: userId)),
                  ),
                  ...state.categories.map((category) {
                    return _buildTab(
                      title: category.name,
                      isSelected: state.selectedCategoryId == category.id,
                      onTap: () => context.read<NotesBloc>().add(FilterNotesByCategory(categoryId: category.id, userId: userId)),
                    );
                  }),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              state.isGridView ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
              color: navyColor.withValues(alpha: 0.3),
              size: 22,
            ),
            onPressed: () => context.read<NotesBloc>().add(ToggleViewMode()),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({required String title, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? primaryColor : navyColor.withValues(alpha: 0.08)),
          boxShadow: isSelected 
              ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : navyColor.withValues(alpha: 0.6),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildNotesList(BuildContext context, NotesState state, String userId) {
    // Sembunyikan catatan yang diarsipkan atau dibuang ke sampah dari layar utama
    var displayNotes = state.notes.where((note) => !note.isArchived && !note.isTrashed).toList();

    // Filter berdasarkan pencarian
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      displayNotes = displayNotes.where((note) {
        return note.title.toLowerCase().contains(query) || note.contentText.toLowerCase().contains(query);
      }).toList();
    }

    if (displayNotes.isEmpty) {
      return _buildEmptyState();
    }

    return MasonryGridView.count(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      crossAxisCount: state.isGridView ? 2 : 1,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      itemCount: displayNotes.length,
      itemBuilder: (context, index) {
        final note = displayNotes[index];
        return NoteCard(
          note: note,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteEditorScreen(note: note, userId: userId, categories: state.categories),
              ),
            );
          },
          onLongPress: () => _showNoteOptions(context, note),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_notes.png',
            width: 200,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.note_alt_rounded, size: 60, color: Colors.grey.shade200);
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada catatan',
            style: TextStyle(color: navyColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ayo mulai tulis ide cemerlangmu!',
            style: TextStyle(color: navyColor.withValues(alpha: 0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(String userName, String userId, bool isPremium) {
    return Drawer(
      backgroundColor: const Color(0xFFFBFBFD),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: 'Smart', style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold)),
                        TextSpan(text: 'Notes', style: TextStyle(color: navyColor.withValues(alpha: 0.6), fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: isPremium ? null : () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PaymentMethodScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPremium
                          ? [const Color(0xFFFFB300), const Color(0xFFFF8F00)]
                          : [const Color(0xFF4F64F2), const Color(0xFF3B4CEB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: (isPremium ? Colors.amber : primaryColor).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPremium ? Icons.workspace_premium_rounded : Icons.star_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isPremium ? 'PRO Member' : 'Dapatkan Premium',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Text('DAPATKAN', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 10)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                          child: const Text('AKTIF ✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildDrawerGroup([
                    _buildDrawerItem(Icons.note_outlined, 'Semua Catatan', isSelected: true, onTap: () {
                      Navigator.pop(context);
                      // Muat semua catatan sebelum pindah halaman
                      context.read<NotesBloc>().add(FilterNotesByCategory(categoryId: 'all', userId: userId));
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllNotesManagementScreen(userId: userId)),
                      );
                    }),
                    _buildDrawerItem(Icons.calendar_month_outlined, 'Kalender', onTap: () {
                      Navigator.pop(context);
                      // Muat semua catatan agar filter lokal kalender berfungsi maksimal
                      context.read<NotesBloc>().add(FilterNotesByCategory(categoryId: 'all', userId: userId));
                      Navigator.push(context, MaterialPageRoute(builder: (context) => CalendarScreen(userId: userId)));
                    }),
                  ]),
                  const SizedBox(height: 16),
                  _buildDrawerGroup([
                    _buildDrawerItem(Icons.star_outline_rounded, 'Favorit', onTap: () {
                      Navigator.pop(context);
                      context.read<NotesBloc>().add(FilterNotesByCategory(categoryId: 'all', userId: userId));
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllNotesManagementScreen(userId: userId, filterFavorite: true)),
                      );
                    }),
                    _buildDrawerItem(Icons.archive_outlined, 'Arsip', onTap: () {
                      Navigator.pop(context);
                      context.read<NotesBloc>().add(FilterNotesByCategory(categoryId: 'all', userId: userId));
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllNotesManagementScreen(userId: userId, filterArchive: true)),
                      );
                    }),
                    _buildDrawerItem(Icons.delete_outline_rounded, 'Sampah', onTap: () {
                      Navigator.pop(context);
                      context.read<NotesBloc>().add(FilterNotesByCategory(categoryId: 'all', userId: userId));
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllNotesManagementScreen(userId: userId, filterTrash: true)),
                      );
                    }),
                  ]),
                  const SizedBox(height: 16),
                  _buildDrawerGroup([
                    _buildDrawerItem(Icons.settings_outlined, 'Pengaturan', onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    }),
                    _buildDrawerItem(Icons.logout_rounded, 'Keluar', color: Colors.red, onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog();
                    }),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {bool isSelected = false, Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? (isSelected ? primaryColor : navyColor.withValues(alpha: 0.6))),
      title: Text(title, style: TextStyle(color: color ?? navyColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }
}
