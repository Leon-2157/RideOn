import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';

/// Item data model for custom navigation tabs
class CustomNavItem {
  final String label;
  final String iconAsset;
  final String keyName;

  const CustomNavItem({
    required this.label,
    required this.iconAsset,
    required this.keyName,
  });
}

/// Custom Bottom Navigation Bar matching Figma `Navbar/Group 279.png`
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<CustomNavItem> items = [
    CustomNavItem(
      label: 'Beranda',
      iconAsset: 'assets/icons/navbar/ic_nav_beranda.png',
      keyName: 'btn_nav_beranda',
    ),
    CustomNavItem(
      label: 'Favorite',
      iconAsset: 'assets/icons/navbar/ic_nav_favorite.png',
      keyName: 'btn_nav_favorite',
    ),
    CustomNavItem(
      label: 'Aktivitas',
      iconAsset: 'assets/icons/navbar/ic_nav_aktivitas.png',
      keyName: 'btn_nav_aktivitas',
    ),
    CustomNavItem(
      label: 'chat',
      iconAsset: 'assets/icons/navbar/ic_nav_chat.png',
      keyName: 'btn_nav_chat',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = currentIndex == index;

              return GestureDetector(
                key: Key(item.keyName),
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(index),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOutCubic,
                    width: 50.0,
                    height: 40.0,
                    padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            item.iconAsset,
                            width: 18.0,
                            height: 18.0,
                            color: isActive ? AppColors.dark : Colors.white,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            item.label,
                            style: GoogleFonts.roboto(
                              fontSize: 9.0,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                              color: isActive ? AppColors.dark : Colors.white,
                              letterSpacing: 0.1,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
