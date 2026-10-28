import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../aktivitas/presentation/pages/aktivitas_screen.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
import '../../../favorit/presentation/pages/favorit_screen.dart';
import '../../../flexfood/presentation/pages/flexfood_screen.dart';
import '../../../flexride/presentation/pages/flexride_screen.dart';
import '../../../flexsend/presentation/pages/flexsend_screen.dart';
import '../../../home/presentation/pages/beranda_screen.dart';
import '../../../pengaturan/presentation/pages/pengaturan_akun_screen.dart';

/// MainScreen containing the BottomNavigationBar strictly matching Figma:
/// - Tab 0: Beranda
/// - Tab 1: Favorite
/// - Tab 2: Aktivitas
/// - Tab 3: chat
class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _navigateToPengaturan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PengaturanAkunScreen(),
      ),
    );
  }

  void _onServiceTap(int serviceIndex) {
    if (serviceIndex == 0) {
      // FlexRide
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const FlexRideScreen(),
        ),
      );
    } else if (serviceIndex == 1) {
      // FlexFood
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const FlexFoodScreen(),
        ),
      );
    } else if (serviceIndex == 2) {
      // FlexSend
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const FlexSendScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          BerandaScreen(
            onLoginTap: _navigateToLogin,
            onProfileTap: _navigateToPengaturan,
            onServiceTap: _onServiceTap,
          ),
          const FavoritScreen(),
          const AktivitasScreen(),
          const ChatScreen(initialShowDetail: false),
        ],
      ),
      bottomNavigationBar: _buildBottomNavbar(),
    );
  }

  Widget _buildBottomNavbar() {
    final navItems = [
      {
        'label': 'Beranda',
        'icon': Icons.home_rounded,
      },
      {
        'label': 'Favorite',
        'icon': Icons.favorite_rounded,
      },
      {
        'label': 'Aktivitas',
        'icon': Icons.receipt_long_rounded,
      },
      {
        'label': 'chat',
        'icon': Icons.chat_bubble_rounded,
      },
    ];

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final item = navItems[index];
            final isActive = _currentIndex == index;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 22,
                      color: isActive ? AppColors.primary : AppColors.dark.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['label'] as String,
                      style: GoogleFonts.roboto(
                        fontSize: 9.5,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                        color: isActive ? AppColors.primary : AppColors.dark.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
