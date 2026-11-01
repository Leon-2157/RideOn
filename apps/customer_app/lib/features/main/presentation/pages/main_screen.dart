import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? _userName;
  String? _photoUrl;

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
    _loadUserData();
  }

  void _loadUserData() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userName = user.displayName;
          _photoUrl = user.photoURL;
        });

        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((doc) {
          if (doc.exists && mounted) {
            final data = doc.data()!;
            setState(() {
              _userName = data['name'] ?? _userName;
              final pUrl = data['photoUrl'] as String?;
              if (pUrl != null && pUrl.isNotEmpty) {
                _photoUrl = pUrl;
              }
            });
          }
        });
      }
    } catch (_) {}
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _navigateToPengaturan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PengaturanAkunScreen(),
      ),
    );
    _loadUserData();
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
            userName: _userName,
            photoUrl: _photoUrl,
            onLoginTap: _navigateToLogin,
            onProfileTap: _navigateToPengaturan,
            onServiceTap: _onServiceTap,
            onFoodTap: (food) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FlexFoodScreen(
                    initialState: FlexFoodState.grid,
                    initialFood: {
                      'title': food.title,
                      'desc': food.description,
                      'resto': food.description,
                      'price': food.price,
                      'image': food.imageAsset,
                    },
                  ),
                ),
              );
            },
          ),
          FavoritScreen(
            onBack: () => setState(() => _currentIndex = 0),
            onSelectFood: (_) => _onServiceTap(1),
          ),
          AktivitasScreen(
            onBack: () => setState(() => _currentIndex = 0),
          ),
          ChatScreen(
            initialShowDetail: false,
            onBack: () => setState(() => _currentIndex = 0),
          ),
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
