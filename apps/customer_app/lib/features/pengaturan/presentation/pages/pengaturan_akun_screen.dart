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

// Modules Import
import '../modules/pengaturan_akun/pengaturan_top_header.dart';
import '../modules/pengaturan_akun/profil_header_card.dart';
import '../modules/pengaturan_akun/menu_item_tile.dart';
import '../modules/pengaturan_akun/privacy_policy_card.dart';
import '../modules/pengaturan_akun/theme_bottom_sheet.dart';
import '../modules/pengaturan_akun/tombol_keluar_akun.dart';

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
export '../modules/pengaturan_akun/pengaturan_top_header.dart';
export '../modules/pengaturan_akun/privacy_policy_card.dart';
export '../modules/pengaturan_akun/theme_bottom_sheet.dart';

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
              if (email != null &&
                  email.isNotEmpty &&
                  !email.endsWith('@rideon.id') &&
                  isVerif) {
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
    ThemeBottomSheet.show(
      context,
      currentTheme: _selectedTheme,
      onThemeSelected: (theme) {
        setState(() {
          _selectedTheme = theme;
        });
      },
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
          PengaturanTopHeader(
            title: 'Pengaturan Akun',
            onBack: () => Navigator.of(context).pop(),
          ),

          // Scrollable Settings Content
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
                        final result = await Navigator.of(context)
                            .push<Map<String, dynamic>>(
                          MaterialPageRoute(
                            builder: (context) => UbahProfilScreen(
                              currentName: _userName,
                              currentPhotoUrl: _photoUrl,
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            if (result['name'] != null &&
                                (result['name'] as String).isNotEmpty) {
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
                            builder: (context) =>
                                NomorWaScreen(currentPhone: _phoneNumber),
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
                      subtitle: (_isEmailAdded && _isEmailVerified)
                          ? _email
                          : '• Belum ditambahkan',
                      badgeText: (_isEmailAdded && _isEmailVerified)
                          ? 'Aktif'
                          : '+Tambahkan',
                      badgeColor: const Color(0xFF8CE1D7),
                      badgeTextColor: const Color(0xFF114B44),
                      onTap: () async {
                        final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (context) => AlamatEmailScreen(
                              currentEmail:
                                  (_isEmailAdded && _isEmailVerified)
                                      ? _email
                                      : '',
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
                  PrivacyPolicyCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const KebijakanPrivasiScreen(),
                        ),
                      );
                    },
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
