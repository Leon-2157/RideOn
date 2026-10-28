import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../auth/presentation/pages/login_screen.dart';

/// Halaman Pengaturan Akun strictly matching Figma customer designs:
/// - Node [44:1951] (pengaturan polos)
/// - Ubah Tema Modal [44:2292] (mode terang, mode gelap, ikuti sistem)
/// - Keluar Modal [44:3290] (keluar atau tidak)
/// - Sub-screens:
///   * Ubah Profil (ubah profil.png, pilih foto profil.png)
///   * Nomor WhatsApp (NOMOR WA-1.png)
///   * Alamat Email (hubungi email.png)
///   * Keamanan Akun (ubah sandi.png)
///   * Lokasi Anda (atur lokadi.png)
///   * Kebijakan Privasi & Syarat (syarat dan ketentuan.png)
class PengaturanAkunScreen extends StatefulWidget {
  const PengaturanAkunScreen({super.key});

  @override
  State<PengaturanAkunScreen> createState() => _PengaturanAkunScreenState();
}

class _PengaturanAkunScreenState extends State<PengaturanAkunScreen> {
  String _selectedTheme = 'Ikuti Sistem';
  String _userName = 'Peter';
  String _phoneNumber = '0812-3456-7890';
  String _email = 'Belum ditambahkan';
  bool _isEmailAdded = false;

  void _showThemeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String tempTheme = _selectedTheme;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header: Icon + Title + Close Button
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1832),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.palette_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pilih Tema',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1832),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1B1832),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Color(0xFF1B1832),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE2DCFE)),
                  const SizedBox(height: 18),

                  // Option 1: Mode Terang
                  _buildThemeOptionCard(
                    title: 'Mode Terang',
                    subtitle: 'Tampilan cerah',
                    icon: Icons.wb_sunny_outlined,
                    isSelected: tempTheme == 'Mode Terang',
                    onTap: () => setModalState(() => tempTheme = 'Mode Terang'),
                  ),
                  const SizedBox(height: 12),

                  // Option 2: Mode Gelap
                  _buildThemeOptionCard(
                    title: 'Mode Gelap',
                    subtitle: 'Tampilan Gelap',
                    icon: Icons.nightlight_round,
                    isSelected: tempTheme == 'Mode Gelap',
                    onTap: () => setModalState(() => tempTheme = 'Mode Gelap'),
                  ),
                  const SizedBox(height: 12),

                  // Option 3: Ikuti Sistem
                  _buildThemeOptionCard(
                    title: 'Ikuti Sistem',
                    subtitle: 'Sesuai Perangkat Anda',
                    icon: Icons.sync_rounded,
                    isSelected: tempTheme == 'Ikuti Sistem',
                    onTap: () => setModalState(() => tempTheme = 'Ikuti Sistem'),
                  ),
                  const SizedBox(height: 22),

                  // Bottom Selesai Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTheme = tempTheme;
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B1832),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'SELESAI',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EEFF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF1B1832)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1832),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: const Color(0xFF6B6680),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1B1832),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1B1832),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 36),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              decoration: BoxDecoration(
                color: const Color(0xFF7E799B).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Keluar dari akun anda?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // KELUAR Button (Red)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: Container(
                      height: 44,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE83535), Color(0xFFD61F1F)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE83535).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'KELUAR',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // BATALKAN Button (Silver/Gray)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 44,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1E4EA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'BATALKAN',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B1832),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom Gradient Header matching Figma
          _buildTopHeader(context),

          // Scrollable Settings Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Card
                  _buildProfileCard(),
                  const SizedBox(height: 20),

                  // Section Title: PENGATURAN AKUN
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Text(
                      'PENGATURAN AKUN',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF17152B),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),

                  // Settings Group Card
                  _buildSettingsCard([
                    _buildSettingItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Ubah Profil',
                      subtitle: 'Nama dan foto akun',
                      onTap: () async {
                        final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (context) => UbahProfilScreen(currentName: _userName),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _userName = result;
                          });
                        }
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.palette_outlined,
                      title: 'Ubah Tema',
                      subtitle: 'Sesuaikan Tema',
                      onTap: _showThemeBottomSheet,
                    ),
                    _buildSettingItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Nomor WhatsApp',
                      subtitle: '• $_phoneNumber',
                      badgeText: 'Aktif',
                      onTap: () async {
                        final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (context) => NomorWaScreen(currentPhone: _phoneNumber),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _phoneNumber = result;
                          });
                        }
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.mail_outline_rounded,
                      title: 'Alamat Email',
                      subtitle: _isEmailAdded ? _email : '• Belum ditambahkan',
                      badgeText: _isEmailAdded ? 'Aktif' : '+Tambahkan',
                      onTap: () async {
                        final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (context) => const AlamatEmailScreen(),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _email = result;
                            _isEmailAdded = true;
                          });
                        }
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.lock_outline_rounded,
                      title: 'Keamanan Akun',
                      subtitle: 'Ubah kata sandi akun',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const KeamananAkunScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.location_on_outlined,
                      title: 'Lokasi Anda',
                      subtitle: 'Atur lokasi',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LokasiAndaScreen(),
                          ),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Kebijakan Privasi & syarat Card
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const KebijakanPrivasiScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC7BCFE),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B48FC).withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD6CEFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kebijakan Privasi & syarat',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF17152B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ketentuan Penggunaan Platfrom',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10.5,
                                    color: const Color(0xFF4C4566),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: Color(0xFF17152B),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // KELUAR AKUN Button
                  Center(
                    child: GestureDetector(
                      onTap: _showLogoutDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1832),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'KELUAR AKUN',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB4A5FE),
            Color(0xFFE2DCFE),
            Color(0xFFF7F5FF),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6E0FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Color(0xFF17152B),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Pengaturan Akun',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 34), // Balancing back button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFC7BCFE),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B48FC).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Peter Avatar with white ring border
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: const DecorationImage(
                image: AssetImage(AppAssets.userAvatar),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // User Info (Name + Phone)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF17152B),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 13,
                      color: Color(0xFF17152B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _phoneNumber,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Verified Pill Badge (Cyan/Teal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF8CE1D7),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Verified',
              style: GoogleFonts.roboto(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF114B44),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: const Color(0xFFC7BCFE),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B48FC).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6CEFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: 10.5,
                        color: const Color(0xFF4C4566),
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8CE1D7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF114B44),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUB-SCREEN 1: Ubah Profil (Figma ubah profil.png & pilih foto profil.png)
// ---------------------------------------------------------------------------
class UbahProfilScreen extends StatefulWidget {
  final String currentName;

  const UbahProfilScreen({super.key, required this.currentName});

  @override
  State<UbahProfilScreen> createState() => _UbahProfilScreenState();
}

class _UbahProfilScreenState extends State<UbahProfilScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showPilihFotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1832),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pilih Foto Profil',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1832),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildFotoSourceOption(
                icon: Icons.camera_alt_rounded,
                title: 'Pilih Foto Profil',
                subtitle: 'Buka Kamera dan Ambil Foto',
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Foto kamera dipilih')),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildFotoSourceOption(
                icon: Icons.image_rounded,
                title: 'Pilih Dari Galeri',
                subtitle: 'Pilih Foto Dari Perangkat',
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Foto galeri dipilih')),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B1832),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'BATAL',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFotoSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EEFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF6B48FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1832),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: const Color(0xFF6B6680),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF1B1832)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildSubHeader(context, 'Ubah Profil'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFC7BCFE),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B48FC).withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with Camera Badge
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              image: const DecorationImage(
                                image: AssetImage(AppAssets.userAvatar),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: _showPilihFotoSheet,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B1832),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nama Lengkap Label
                    Text(
                      'Nama Lengkap',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Input Field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCD7FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _nameController,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF17152B),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SIMPAN PERUBAHAN Button
                    GestureDetector(
                      onTap: () {
                        final newName = _nameController.text.trim();
                        if (newName.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Perubahan profil berhasil disimpan!'),
                              backgroundColor: Color(0xFF6B48FC),
                            ),
                          );
                          Navigator.of(context).pop(newName);
                        }
                      },
                      child: Container(
                        height: 44,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1832),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.save_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SIMPAN PERUBAHAN',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUB-SCREEN 2: Nomor WhatsApp (Figma NOMOR WA-1.png)
// ---------------------------------------------------------------------------
class NomorWaScreen extends StatefulWidget {
  final String currentPhone;

  const NomorWaScreen({super.key, required this.currentPhone});

  @override
  State<NomorWaScreen> createState() => _NomorWaScreenState();
}

class _NomorWaScreenState extends State<NomorWaScreen> {
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildSubHeader(context, 'Nomor WhatsApp'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7BCFE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Nomor WhatsApp terdaftar saat ini: ${widget.currentPhone}\n'
                      'Untuk menggantinya, masukkan nomor baru Anda. Kami akan mengirimkan 6 digit kode OTP verifikasi ke nomor baru.',
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        color: const Color(0xFF17152B),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7BCFE),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfirmasi Kata Sandi Akun',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInputField(
                          controller: _passwordController,
                          hintText: 'Masukkan kata sandi akun',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Nomor WhatsApp Baru',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInputField(
                          controller: _phoneController,
                          hintText: '084567891234',
                          icon: Icons.chat_bubble_outline_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () {
                            final newPhone = _phoneController.text.trim();
                            if (newPhone.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kode OTP telah dikirimkan ke WhatsApp Anda!'),
                                  backgroundColor: Color(0xFF6B48FC),
                                ),
                              );
                              Navigator.of(context).pop(newPhone);
                            }
                          },
                          child: Container(
                            height: 44,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B1832),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'KIRIM KODE OTP WHATSAPP',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUB-SCREEN 3: Alamat Email (Figma hubungi email.png)
// ---------------------------------------------------------------------------
class AlamatEmailScreen extends StatefulWidget {
  const AlamatEmailScreen({super.key});

  @override
  State<AlamatEmailScreen> createState() => _AlamatEmailScreenState();
}

class _AlamatEmailScreenState extends State<AlamatEmailScreen> {
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildSubHeader(context, 'Alamat Email'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7BCFE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6CEFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hubungkan Email Anda',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tambahkan alamat email resmi untuk menerima e-receipt bukti sewa transaksi dan memudahkan pemulihan akun sewaktu-waktu.',
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  color: const Color(0xFF17152B),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7BCFE),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfirmasi Kata Sandi Akun',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInputField(
                          controller: _passwordController,
                          hintText: 'Masukkan kata sandi akun',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Alamat Email Aktif',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInputField(
                          controller: _emailController,
                          hintText: 'peter@gmail.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () {
                            final email = _emailController.text.trim();
                            if (email.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Email berhasil ditambahkan!'),
                                  backgroundColor: Color(0xFF6B48FC),
                                ),
                              );
                              Navigator.of(context).pop(email);
                            }
                          },
                          child: Container(
                            height: 44,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B1832),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'SIMPAN & KIRIM OTP',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUB-SCREEN 4: Keamanan Akun (Figma ubah sandi.png)
// ---------------------------------------------------------------------------
class KeamananAkunScreen extends StatefulWidget {
  const KeamananAkunScreen({super.key});

  @override
  State<KeamananAkunScreen> createState() => _KeamananAkunScreenState();
}

class _KeamananAkunScreenState extends State<KeamananAkunScreen> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildSubHeader(context, 'Keamanan Akun'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFC7BCFE),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kata Sandi Saat ini *',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPasswordInput(
                      controller: _oldPassController,
                      hintText: 'Masukkan sandi saat ini',
                      obscure: _obscureOld,
                      onToggle: () => setState(() => _obscureOld = !_obscureOld),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'Kata Sandi Baru *',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPasswordInput(
                      controller: _newPassController,
                      hintText: 'Minimal 8 karakter',
                      obscure: _obscureNew,
                      onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'Konfirmasi Sandi Baru',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPasswordInput(
                      controller: _confirmPassController,
                      hintText: 'Ketik ulang sandi baru',
                      obscure: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kata sandi berhasil diperbarui!'),
                            backgroundColor: Color(0xFF6B48FC),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        height: 44,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1832),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'SIMPAN SANDI BARU',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordInput({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDCD7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.roboto(fontSize: 13, color: const Color(0xFF17152B)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.roboto(fontSize: 12, color: const Color(0xFF6B6680)),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: const Color(0xFF17152B),
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUB-SCREEN 5: Lokasi Anda (Figma atur lokadi.png)
// ---------------------------------------------------------------------------
class LokasiAndaScreen extends StatefulWidget {
  const LokasiAndaScreen({super.key});

  @override
  State<LokasiAndaScreen> createState() => _LokasiAndaScreenState();
}

class _LokasiAndaScreenState extends State<LokasiAndaScreen> {
  String _currentAddress = 'Klik tombol GPS di atas untuk mengisi alamat secara otomatis.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildSubHeader(context, 'Lokasi Anda'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFC7BCFE),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6CEFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.map_rounded,
                        size: 26,
                        color: Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Atur Lokasi Anda',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // GPS Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentAddress = 'Jl. Pegangsaan Timur No. 56, Jakarta Pusat (Titik Akurat GPS)';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lokasi GPS berhasil didapatkan!'),
                            backgroundColor: Color(0xFF6B48FC),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCD7FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.navigation_rounded,
                              size: 16,
                              color: Color(0xFF17152B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Gunakan Titik GPS Saat Ini',
                              style: GoogleFonts.roboto(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Detail Alamat
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Detail Alamat Lengkap',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _currentAddress,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: const Color(0xFF4C4566),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SIMPAN TITIK LOKASI Button
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Titik lokasi berhasil disimpan!'),
                            backgroundColor: Color(0xFF6B48FC),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        height: 44,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1832),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'SIMPAN TITIK LOKASI',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUB-SCREEN 6: Kebijakan Privasi & Syarat (Figma syarat dan ketentuan.png)
// ---------------------------------------------------------------------------
class KebijakanPrivasiScreen extends StatelessWidget {
  const KebijakanPrivasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildSubHeader(context, 'Kebijakan Privasi & syarat'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2DCFE), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC7BCFE),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Syarat & Ketentuan RideOn',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ketentuan umum penggunaan layanan transportasi',
                            style: GoogleFonts.roboto(
                              fontSize: 10.5,
                              color: const Color(0xFF4C4566),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body Terms
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang di RideOn. Dengan mendaftar dan menggunakan platform ini, '
                            'Anda menyatakan tunduk dan terikat pada syarat dan ketentuan berikut sesuai hukum yang berlaku di Republik Indonesia.',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: const Color(0xFF4C4566),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSectionTitle('1. Ketentuan Umum & Definisi'),
                          _buildSectionBody(
                            '• RideOn adalah platform perantara yang mempertemukan pihak yang menyediakan layanan transportasi (Mitra Pengemudi) dengan pihak yang membutuhkan layanan perjalanan (Penumpang/Customer).\n'
                            '• RideOn tidak memiliki, menguasai, atau mengelola armada kendaraan yang digunakan oleh Mitra Pengemudi di dalam platform ini.\n'
                            '• Pengguna wajib berusia minimal 17 tahun dan/atau memiliki identitas resmi (KTP/SIM/Paspor) yang sah menurut hukum Republik Indonesia.',
                          ),
                          const SizedBox(height: 14),
                          _buildSectionTitle('2. Tanggung Jawab & Kewajiban Customer'),
                          _buildSectionBody(
                            '• Customer wajib memberikan informasi titik penjemputan dan titik tujuan yang asli dan valid saat melakukan transaksi pemesanan perjalanan.\n'
                            '• Customer dilarang keras membawa barang terlarang, ilegal, berbahaya, atau hewan yang tidak sesuai dengan kebijakan keselamatan.\n'
                            '• Customer wajib mematuhi peraturan lalu lintas, termasuk menggunakan helm pelindung yang disediakan oleh Mitra Pengemudi.',
                          ),
                          const SizedBox(height: 14),
                          _buildSectionTitle('3. Tanggung Jawab & Hak Mitra Pengemudi (Driver)'),
                          _buildSectionBody(
                            '• Mitra Pengemudi bertanggung jawab penuh atas keselamatan penumpang, kelayakan jalan kendaraan, serta kesesuaian identitas dan plat nomor kendaraan.\n'
                            '• Mitra Pengemudi berhak menolak pesanan jika Customer dinilai mencurigakan atau membawa muatan berlebih.',
                          ),
                          const SizedBox(height: 14),
                          _buildSectionTitle('4. Batasan Tanggung Jawab'),
                          _buildSectionBody(
                            '• RideOn terlepas dari segala tuntutan hukum atas kecelakaan, kehilangan barang bawaan, cedera, atau tindakan kriminal di luar prosedur standar aplikasi.\n'
                            '• Segala sengketa adalah tanggung jawab penuh antara Mitra Pengemudi dan Customer. RideOn bertindak sebagai mediator untuk membantu menyelesaikan perselisihan.',
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.roboto(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF17152B),
      ),
    );
  }

  Widget _buildSectionBody(String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        body,
        style: GoogleFonts.roboto(
          fontSize: 10.5,
          color: const Color(0xFF4C4566),
          height: 1.45,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Sub-Header for Settings Sub-Screens
// ---------------------------------------------------------------------------
Widget _buildSubHeader(BuildContext context, String title) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFB4A5FE),
          Color(0xFFE2DCFE),
          Color(0xFFF7F5FF),
        ],
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: Color(0xFF17152B),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF17152B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 34),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Shared Input Field for Sub-Screens
// ---------------------------------------------------------------------------
Widget _buildInputField({
  required TextEditingController controller,
  required String hintText,
  required IconData icon,
  bool isPassword = false,
  TextInputType keyboardType = TextInputType.text,
}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFDCD7FF),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.6),
        width: 1.2,
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF17152B)),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: const Color(0xFF17152B),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.roboto(
                fontSize: 12,
                color: const Color(0xFF6B6680),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    ),
  );
}
