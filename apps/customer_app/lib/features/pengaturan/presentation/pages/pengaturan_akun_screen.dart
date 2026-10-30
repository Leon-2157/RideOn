import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Sub-Screens Import
import 'ubah_profil_screen.dart';
import 'nomor_wa_screen.dart';
import 'alamat_email_screen.dart';
import 'keamanan_akun_screen.dart';
import 'lokasi_anda_screen.dart';
import 'kebijakan_privasi_screen.dart';

// Widgets Import
import '../widgets/profil_header_card.dart';
import '../widgets/menu_item_tile.dart';
import '../widgets/tombol_keluar_akun.dart';

// Exports untuk menjaga kompatibilitas seluruh import eksternal & test suite
export 'ubah_profil_screen.dart';
export 'atur_posisi_foto_screen.dart';
export 'nomor_wa_screen.dart';
export 'alamat_email_screen.dart';
export 'keamanan_akun_screen.dart';
export 'lokasi_anda_screen.dart';
export 'kebijakan_privasi_screen.dart';
export '../widgets/profil_header_card.dart';
export '../widgets/menu_item_tile.dart';
export '../widgets/tombol_keluar_akun.dart';
export '../widgets/email_verification_dialog.dart';
export '../widgets/country_code_selector.dart';
export '../widgets/crop_frame_painter.dart';
export '../widgets/sub_header_widget.dart';

/// Halaman Utama Pengaturan Akun (Clean Architecture Orchestrator)
/// Menyusun Header, Card 1 (Profil Info), Card 2 (Menu Items), dan Tombol Keluar Akun
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
  String? _photoUrl;
  bool _isEmailAdded = false;
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  void _loadCurrentUserData() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          setState(() {
            _userName = user.displayName!;
          });
        }
        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
          setState(() {
            _phoneNumber = user.phoneNumber!;
          });
        }
        if (user.photoURL != null && user.photoURL!.isNotEmpty) {
          setState(() {
            _photoUrl = user.photoURL;
          });
        }

        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .then((doc) {
          if (doc.exists && mounted) {
            final data = doc.data()!;
            setState(() {
              _userName = data['name'] ?? _userName;
              _phoneNumber = data['phoneNumber'] ?? _phoneNumber;
              final pUrl = data['photoUrl'] as String?;
              if (pUrl != null && pUrl.isNotEmpty) {
                _photoUrl = pUrl;
              }
              final email = (data['email'] as String?)?.trim();
              final isVerif = data['emailVerified'] == true;
              if (email != null && email.isNotEmpty && !email.endsWith('@rideon.id') && isVerif) {
                _email = email;
                _isEmailAdded = true;
                _isEmailVerified = true;
              } else {
                _email = 'Belum ditambahkan';
                _isEmailAdded = false;
                _isEmailVerified = false;
              }
            });
          }
        }).catchError((_) {});
      }
    } catch (_) {}
  }

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
                  // Card 1: Informasi Akun (Avatar, Nama, No HP, Verified Badge)
                  ProfilHeaderCard(
                    userName: _userName,
                    phoneNumber: _phoneNumber,
                    photoUrl: _photoUrl,
                    isVerified: true,
                  ),
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

                  // Card 2: Settings Group Card
                  _buildSettingsCard([
                    MenuItemTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Ubah Profil',
                      subtitle: 'Nama dan foto akun',
                      onTap: () async {
                        final result = await Navigator.of(context).push<Map<String, dynamic>>(
                          MaterialPageRoute(
                            builder: (context) => UbahProfilScreen(
                              currentName: _userName,
                              currentPhotoUrl: _photoUrl,
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            if (result['name'] != null && (result['name'] as String).isNotEmpty) {
                              _userName = result['name'];
                            }
                            if (result['photoUrl'] != null) {
                              _photoUrl = result['photoUrl'];
                            }
                          });
                        }
                      },
                    ),
                    MenuItemTile(
                      icon: Icons.palette_outlined,
                      title: 'Ubah Tema',
                      subtitle: 'Sesuaikan Tema',
                      onTap: _showThemeBottomSheet,
                    ),
                    MenuItemTile(
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
                    MenuItemTile(
                      icon: Icons.mail_outline_rounded,
                      title: 'Alamat Email',
                      subtitle: (_isEmailAdded && _isEmailVerified) ? _email : '• Belum ditambahkan',
                      badgeText: (_isEmailAdded && _isEmailVerified)
                          ? 'Aktif'
                          : '+Tambahkan',
                      badgeColor: const Color(0xFF8CE1D7),
                      badgeTextColor: const Color(0xFF114B44),
                      onTap: () async {
                        final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (context) => AlamatEmailScreen(
                              currentEmail: (_isEmailAdded && _isEmailVerified) ? _email : '',
                              userPhone: _phoneNumber,
                              isEmailVerified: _isEmailVerified,
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _email = result;
                            _isEmailAdded = true;
                            _isEmailVerified = true;
                          });
                          _loadCurrentUserData();
                        }
                      },
                    ),
                    MenuItemTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Keamanan Akun',
                      subtitle: 'Ubah kata sandi akun',
                      onTap: () async {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (context) => const KeamananAkunScreen(),
                          ),
                        );
                        if (result == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kata sandi berhasil diperbarui!'),
                              backgroundColor: Color(0xFF6B48FC),
                            ),
                          );
                        }
                      },
                    ),
                    MenuItemTile(
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

                  // Bottom Logout Button
                  const TombolKeluarAkun(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
