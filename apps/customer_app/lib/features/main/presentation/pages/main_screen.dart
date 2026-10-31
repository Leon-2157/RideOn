import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../aktivitas/presentation/pages/aktivitas_screen.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
import '../../../favorit/presentation/pages/favorit_screen.dart';
import '../../../flexfood/presentation/pages/flexfood_screen.dart';
import '../../../flexride/presentation/pages/flexride_screen.dart';
import '../../../flexsend/presentation/pages/flexsend_screen.dart';
import '../../../home/presentation/pages/beranda_screen.dart';
import '../../../pengaturan/presentation/pages/pengaturan_akun_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';

export '../widgets/custom_bottom_nav_bar.dart';

/// MainScreen containing the BottomNavigationBar strictly matching Figma:
/// - Tab 0: Beranda
/// - Tab 1: Favorite
/// - Tab 2: Aktivitas
/// - Tab 3: chat
class MainScreen extends StatefulWidget {
  final int initialIndex;
  final bool? isLoggedIn;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
    this.isLoggedIn,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  bool get _isLoggedIn {
    if (widget.isLoggedIn != null) return widget.isLoggedIn!;
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return true;
    }
  }

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
            isLoggedIn: _isLoggedIn,
            onLoginTap: _navigateToLogin,
            onProfileTap: _navigateToPengaturan,
            onServiceTap: _onServiceTap,
          ),
          FavoritScreen(
            onBack: () => setState(() => _currentIndex = 0),
            onSelectFood: (_) => _onServiceTap(1),
          ),
          const AktivitasScreen(),
          const ChatScreen(initialShowDetail: false),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
