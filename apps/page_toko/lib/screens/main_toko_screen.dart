import 'package:flutter/material.dart';
import '../widgets/toko_bottom_nav.dart';
import 'home/toko_home_screen.dart';
import 'orders/toko_orders_screen.dart';
import 'menu/toko_menu_screen.dart';
import 'finance/toko_finance_screen.dart';
import 'profile/toko_profile_screen.dart';

class MainTokoScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MainTokoScreen({super.key, required this.onLogout});

  @override
  State<MainTokoScreen> createState() => _MainTokoScreenState();
}

class _MainTokoScreenState extends State<MainTokoScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ponytail: IndexedStack retains tab states during tab switches; switch to PageView if horizontal swipe gesture requested
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TokoHomeScreen(onNavigateTab: _onTabTapped),
          const TokoOrdersScreen(),
          const TokoMenuScreen(),
          const TokoFinanceScreen(),
          TokoProfileScreen(onLogout: widget.onLogout),
        ],
      ),
      bottomNavigationBar: TokoBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
