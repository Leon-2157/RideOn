import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/driver_service.dart';
import '../../services/theme_service.dart';
import '../login_screen.dart';
import 'edit_profile_screen.dart';
import 'driver_verification_screen.dart';
import 'vehicle_info_screen.dart';
import 'security_screen.dart';
import 'privacy_policy_screen.dart';
import 'theme_selection_sheet.dart';
import 'logout_dialog.dart';

/// [AccountSettingsScreen]
/// Implementasi Layar Pengaturan Akun Driver sesuai spesifikasi Figma:
/// - Figma/PengaturanAkun/pengaturan polos awl.png
/// - Figma/PengaturanAkun/pengaturan polos.png
/// - Figma/PengaturanAkun/pengaturan polos-1.png
/// - Figma/PengaturanAkun/keluar atau tidak.png
/// - Figma/PengaturanAkun/mode gelap.png
/// - Figma/PengaturanAkun/mode terang.png
/// - Figma/PengaturanAkun/ikuti sistem.png
class AccountSettingsScreen extends StatefulWidget {
  final DriverService? driverService;
  final String initialDriverName;
  final String initialPlateNumber;
  final VoidCallback? onLogout;

  const AccountSettingsScreen({
    super.key,
    this.driverService,
    this.initialDriverName = 'Joni Utama',
    this.initialPlateNumber = 'BK 4892 ABC',
    this.onLogout,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late String _driverName;
  late String _plateNumber;
  late AppThemeMode _currentTheme;

  DriverService? _driverServiceInstance;
  DriverService get _driverService =>
      _driverServiceInstance ??= widget.driverService ?? DriverService();

  @override
  void initState() {
    super.initState();
    _driverName = widget.initialDriverName;
    _plateNumber = widget.initialPlateNumber;
    _currentTheme = ThemeService().currentTheme;
    ThemeService().addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService().removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        _currentTheme = ThemeService().currentTheme;
      });
    }
  }

  void _handleLogout() async {
    final confirmed = await LogoutDialog.show(
      context,
      onConfirm: () async {
        try {
          await _driverService.signOut();
        } catch (_) {
          // Abaikan error saat testing atau offline
        }

        if (!mounted) return;
        if (widget.onLogout != null) {
          widget.onLogout!();
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
        }
      },
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda telah berhasil keluar.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDarkMode(context);

    final scaffoldBg = isDark ? AppColors.dark : AppColors.white;
    final headerGradientColors = isDark
        ? const [
            Color(0xFF2C274A),
            Color(0xFF201B39),
            Color(0xFF17152B),
          ]
        : const [
            Color(0xFF8B68FC),
            Color(0xFFB4A1FF),
            Color(0xFFEBE6FE),
          ];

    final backBtnBg = isDark
        ? AppColors.white.withValues(alpha: 0.15)
        : AppColors.white.withValues(alpha: 0.5);
    final backBtnIconColor = isDark ? AppColors.white : AppColors.dark;
    final headerTitleColor = isDark ? AppColors.white : AppColors.dark;

    final cardBg = isDark
        ? const Color(0xFF28234B)
        : const Color(0xFFC6BCFF).withValues(alpha: 0.65);
    final textTitleColor = isDark ? AppColors.white : AppColors.dark;
    final plateBg = isDark
        ? const Color(0xFF1E1B2E)
        : AppColors.white.withValues(alpha: 0.9);
    final sectionTitleColor =
        isDark ? const Color(0xFFA59ACF) : const Color(0xFF4B5563);

    final logoutBtnBg = isDark ? AppColors.white : AppColors.dark;
    final logoutBtnFg = isDark ? AppColors.dark : AppColors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
          // Header Bar dengan curved bottom & gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: headerGradientColors,
              ),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: backBtnBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: backBtnIconColor,
                            size: 22,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        'Pengaturan Akun',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: headerTitleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.black : AppColors.primary)
                              .withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar Photo
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/driver_avatar.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Name & Plate
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _driverName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textTitleColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                  ),
                                decoration: BoxDecoration(
                                  color: plateBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: RichText(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: '# ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      TextSpan(
                                        text: _plateNumber,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: textTitleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Verified Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB2DFDB),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00796B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Section Title: PENGATURAN AKUN
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'PENGATURAN AKUN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: sectionTitleColor,
                      ),
                    ),
                  ),

                  // Menu Card 1: 5 Items
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        // Item 1: Ubah Profil
                        _buildMenuItem(
                          icon: Icons.person_outline_rounded,
                          title: 'Ubah Profil',
                          subtitle: 'Nama dan foto akun',
                          isDark: isDark,
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(
                                  initialName: _driverName,
                                ),
                              ),
                            );
                            if (result is String && mounted) {
                              setState(() {
                                _driverName = result;
                              });
                            }
                          },
                        ),

                        // Item 2: Ubah Tema
                        _buildMenuItem(
                          icon: Icons.palette_outlined,
                          title: 'Ubah Tema',
                          subtitle: 'Sesuaikan Tema',
                          showChevron: true,
                          isDark: isDark,
                          onTap: () async {
                            final newTheme = await ThemeSelectionSheet.show(
                              context,
                              currentTheme: _currentTheme,
                            );
                            if (newTheme != null && mounted) {
                              ThemeService().setTheme(newTheme);
                              setState(() {
                                _currentTheme = newTheme;
                              });
                            }
                          },
                        ),

                        // Item 3: Status Verifikasi
                        _buildMenuItem(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'Status Verifikasi',
                          subtitle: 'Status dokumen driver',
                          showChevron: true,
                          isDark: isDark,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DriverVerificationScreen(),
                              ),
                            );
                          },
                        ),

                        // Item 4: Informasi Kendaraan
                        _buildMenuItem(
                          icon: Icons.two_wheeler_rounded,
                          title: 'Informasi Kendaraan',
                          subtitle: 'Jenis motor dan nomor polisi',
                          showChevron: true,
                          isDark: isDark,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const VehicleInfoScreen(),
                              ),
                            );
                          },
                        ),

                        // Item 5: Keamanan Akun
                        _buildMenuItem(
                          icon: Icons.lock_outline_rounded,
                          title: 'Keamanan Akun',
                          subtitle: 'Ubah kata sandi akun',
                          showChevron: true,
                          isLast: true,
                          isDark: isDark,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SecurityScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Menu Card 2: Kebijakan Privasi & syarat
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _buildMenuItem(
                      icon: Icons.shield_outlined,
                      title: 'Kebijakan Privasi & syarat',
                      subtitle: 'Ketentuan Penggunaan Platfrom',
                      isLast: true,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tombol KELUAR AKUN
                  Center(
                    child: SizedBox(
                      width: 190,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: logoutBtnBg,
                          foregroundColor: logoutBtnFg,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text(
                          'KELUAR AKUN',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool showChevron = false,
    bool isLast = false,
  }) {
    final iconBoxBg = isDark
        ? const Color(0xFF38315E)
        : AppColors.white.withValues(alpha: 0.45);
    final iconColor = isDark ? const Color(0xFFC6BCFF) : AppColors.white;
    final itemTitleColor = isDark ? AppColors.white : AppColors.dark;
    final itemSubColor =
        isDark ? const Color(0xFFA59ACF) : const Color(0xFF4B5563);
    final chevronColor = isDark ? AppColors.white : AppColors.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBoxBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: itemTitleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: itemSubColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right,
                  color: chevronColor,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
