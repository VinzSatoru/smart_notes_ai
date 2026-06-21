import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/forgot_password_screen.dart';
import '../../../../core/theme/theme_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Color primaryColor = const Color(0xFF4F64F2);
  final Color navyColor = const Color(0xFF1E293B);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengaturan',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          String userName = 'Pengguna';
          String userEmail = 'user@example.com';
          bool isPremium = false;
          
          if (authState is Authenticated) {
            userName = authState.user.name;
            userEmail = authState.user.email;
            isPremium = authState.user.isPremium;
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Profil Pengguna
              _buildProfileCard(userName, userEmail, isPremium),
              const SizedBox(height: 32),

              // Preferensi Aplikasi
              _buildSectionTitle('Preferensi Aplikasi'),
              _buildSettingsCard([
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, themeMode) {
                    final isDarkMode = themeMode == ThemeMode.dark || 
                        (themeMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);
                    return _buildSwitchTile(
                      icon: Icons.dark_mode_rounded,
                      iconColor: const Color(0xFF6366F1),
                      title: 'Mode Gelap',
                      subtitle: 'Gunakan tema gelap untuk kenyamanan mata',
                      value: isDarkMode,
                      onChanged: (val) {
                        context.read<ThemeCubit>().toggleTheme(val);
                      },
                    );
                  }
                ),
              ]),
              const SizedBox(height: 24),

              // Keamanan & Privasi
              _buildSectionTitle('Keamanan & Privasi'),
              _buildSettingsCard([
                _buildActionTile(
                  icon: Icons.lock_reset_rounded,
                  iconColor: const Color(0xFFEC4899),
                  title: 'Ubah Kata Sandi',
                  subtitle: 'Kirim link reset ke email Anda',
                  onTap: () {
                    // Navigasi ke Forgot Password Screen buatan teman
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 24),

              // Data & Penyimpanan
              _buildSectionTitle('Data & Penyimpanan'),
              _buildSettingsCard([
                _buildActionTile(
                  icon: Icons.cleaning_services_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Bersihkan Cache',
                  subtitle: 'Kosongkan memori sementara',
                  onTap: () {
                    PaintingBinding.instance.imageCache.clear();
                    PaintingBinding.instance.imageCache.clearLiveImages();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache memori berhasil dibersihkan!')),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 24),

              // Tentang
              _buildSectionTitle('Tentang'),
              _buildSettingsCard([
                _buildActionTile(
                  icon: Icons.help_outline_rounded,
                  iconColor: const Color(0xFF0EA5E9),
                  title: 'Pusat Bantuan & FAQ',
                  onTap: () => _showFAQDialog(context),
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF64748B),
                  title: 'Versi Aplikasi',
                  subtitle: 'v1.1.0 (Build 24)',
                  showArrow: false,
                  onTap: () => _showVersionDialog(context),
                ),
              ]),
              
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  void _showFAQDialog(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('Pusat Bantuan & FAQ', style: TextStyle(color: textColor)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Q: Bagaimana cara kerja fitur AI?', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 4),
              Text('A: Buka halaman editor catatan, ketuk ikon AI, lalu Anda bisa merekam suara untuk diubah menjadi teks (Transkripsi) atau merangkum tulisan.', style: TextStyle(color: textColor)),
              const SizedBox(height: 16),
              Text('Q: Berapa batas pemakaian AI?', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 4),
              Text('A: Pengguna gratis mendapatkan 3x transkripsi, 5x rangkuman, dan 10 menit batas rekam per hari. Upgrade ke PRO untuk akses tanpa batas.', style: TextStyle(color: textColor)),
              const SizedBox(height: 16),
              Text('Q: Apakah catatan saya aman?', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 4),
              Text('A: Ya, catatan Anda disimpan secara aman dan disinkronisasi ke server kami agar bisa diakses kapan saja.', style: TextStyle(color: textColor)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showVersionDialog(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.info_outline_rounded, size: 64, color: Color(0xFF64748B)),
            const SizedBox(height: 24),
            Text('Smart Notes AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 4),
            Text('Versi 1.1.0 (Build 24)', style: TextStyle(color: textColor.withValues(alpha: 0.7))),
            const SizedBox(height: 24),
            Text('© 2026 Smart Notes AI Team', style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.5))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String name, String email, bool isPremium) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = Theme.of(context).colorScheme.onSurfaceVariant;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: textColor.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F64F2), Color(0xFF3B4CEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  color: Color(0xFF4F64F2),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = Theme.of(context).colorScheme.onSurfaceVariant;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = Theme.of(context).colorScheme.onSurfaceVariant;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                color: subtitleColor.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.1)),
    );
  }
}
