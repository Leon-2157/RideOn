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
import 'package:rideon/features/chat/presentation/pages/chat_screen.dart';

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
  String _phoneNumber = '';
  String _email = 'Belum ditambahkan';
  String? _photoUrl;
  bool _isPhoneAdded = false;
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
        if (user.phoneNumber != null && user.phoneNumber!.trim().isNotEmpty) {
          setState(() {
            _phoneNumber = user.phoneNumber!;
            _isPhoneAdded = true;
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
            final phone = (data['phoneNumber'] as String?)?.trim();
            final bool hasValidPhone = phone != null &&
                phone.isNotEmpty &&
                phone != '0812-3456-7890' &&
                phone != 'Belum ditambahkan';

            setState(() {
              _userName = data['name'] ?? _userName;
              if (hasValidPhone) {
                _phoneNumber = phone;
                _isPhoneAdded = true;
              } else {
                _phoneNumber = '';
                _isPhoneAdded = false;
              }
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
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF9F88FD),
            Color(0xFFBAA7FD),
            Color(0xFFEFEAFF),
            Color(0xFFFFFFFF),
          ],
          stops: [0.0, 0.45, 0.85, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Colors.white,
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
                      color: const Color(0xFF1E143E),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 36), // Balancing back button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    // Sisipkan divider pemisah putih transparan lembut di antara setiap baris menu
    final List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.2),
            indent: 14,
            endIndent: 14,
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF6B48FC),
            Color(0xFFC6BCFF),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B48FC).withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: dividedChildren,
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
                  // Card 1: Informasi Akun (Avatar, Nama, No HP, Verified Badge jika sudah ada nomor WA)
                  ProfilHeaderCard(
                    userName: _userName,
                    phoneNumber: _phoneNumber,
                    photoUrl: _photoUrl,
                    isVerified: _isPhoneAdded,
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
                      subtitle: _isPhoneAdded
                          ? '• $_phoneNumber'
                          : 'Belum ditambahkan',
                      badgeText: _isPhoneAdded ? 'Aktif' : '+Tambahkan',
                      badgeColor: _isPhoneAdded
                          ? const Color(0xFF8CE1D7)
                          : const Color(0xFFF2EFFF),
                      badgeTextColor: _isPhoneAdded
                          ? const Color(0xFF114B44)
                          : const Color(0xFF6B48FC),
                      onTap: () async {
                        final result = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (context) => NomorWaScreen(
                              currentPhone: _isPhoneAdded ? _phoneNumber : '',
                            ),
                          ),
                        );
                        if (result != null && result.trim().isNotEmpty) {
                          setState(() {
                            _phoneNumber = result.trim();
                            _isPhoneAdded = true;
                          });
                          _loadCurrentUserData();
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

                  // Card Gabungan: Kebijakan Privasi & Customer Service
                  _buildSettingsCard([
                    MenuItemTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Kebijakan Privasi & syarat',
                      subtitle: 'Ketentuan Penggunaan Platform',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const KebijakanPrivasiScreen(),
                          ),
                        );
                      },
                    ),
                    MenuItemTile(
                      icon: Icons.support_agent_rounded,
                      title: 'Customer Service',
                      subtitle: 'Bantuan & Hubungi Layanan CS',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ChatScreen(
                              showBackButton: true,
                              initialShowDetail: true,
                              isCustomerService: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ]),
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
