import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
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
  bool _autoSync = true;
  bool _biometricAuth = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: navyColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengaturan',
          style: TextStyle(color: navyColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          String userName = 'Pengguna';
          String userEmail = 'user@example.com';
          
          if (authState is Authenticated) {
            userName = authState.user.name;
            userEmail = authState.user.email;
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Profil Pengguna
              _buildProfileCard(userName, userEmail),
              const SizedBox(height: 32),

              // Preferensi Aplikasi
              _buildSectionTitle('Preferensi Aplikasi'),
              _buildSettingsCard([
                _buildSwitchTile(
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Mode Gelap (BETA)',
                  subtitle: 'Gunakan tema gelap untuk kenyamanan mata',
                  value: _isDarkMode,
                  onChanged: (val) => setState(() => _isDarkMode = val),
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.sync_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Sinkronisasi Otomatis',
                  subtitle: 'Simpan catatan ke cloud secara otomatis',
                  value: _autoSync,
                  onChanged: (val) => setState(() => _autoSync = val),
                ),
              ]),
              const SizedBox(height: 24),

              // Keamanan & Privasi
              _buildSectionTitle('Keamanan & Privasi'),
              _buildSettingsCard([
                _buildSwitchTile(
                  icon: Icons.fingerprint_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Kunci Biometrik',
                  subtitle: 'Gunakan sidik jari untuk membuka aplikasi',
                  value: _biometricAuth,
                  onChanged: (val) => setState(() => _biometricAuth = val),
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.lock_reset_rounded,
                  iconColor: const Color(0xFFEC4899),
                  title: 'Ubah Kata Sandi',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur ubah kata sandi akan segera hadir!')),
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
                  subtitle: '12.4 MB ruang dapat dibebaskan',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache berhasil dibersihkan!')),
                    );
                  },
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.download_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Ekspor Catatan',
                  subtitle: 'Simpan semua catatan ke format PDF/TXT',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur ekspor catatan akan segera hadir!')),
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
                  onTap: () {},
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF64748B),
                  title: 'Versi Aplikasi',
                  subtitle: 'v1.1.0 (Build 24)',
                  showArrow: false,
                  onTap: () {},
                ),
              ]),
              
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: navyColor.withValues(alpha: 0.05)),
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
                    color: navyColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: navyColor.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: navyColor.withValues(alpha: 0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: navyColor.withValues(alpha: 0.05)),
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
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: navyColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: navyColor.withValues(alpha: 0.4),
              ),
            )
          : null,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: primaryColor,
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: navyColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: navyColor.withValues(alpha: 0.4),
              ),
            )
          : null,
      trailing: showArrow
          ? Icon(Icons.chevron_right_rounded, color: navyColor.withValues(alpha: 0.2))
          : null,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 60, right: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: navyColor.withValues(alpha: 0.05),
      ),
    );
  }
}
