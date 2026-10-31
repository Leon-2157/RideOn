import 'package:flutter/material.dart';
import 'package:rideon/core/constants/app_assets.dart';
import '../modules/favorite_card/favorite_card_widget.dart';
import '../modules/header/favorit_header.dart';

export '../modules/favorite_card/favorite_card_widget.dart';
export '../modules/header/favorit_header.dart';

/// Halaman Favorit strictly based on Figma node [44:9160] (favorit.png):
/// - Header gradient horizontal lavender (#9F88FD) ke putih (#FFFFFF) dengan logo putih RideOn
/// - Character banner: Perempuan dengan speech bubble 'Cari Kembali favorit Mu!'
/// - 3-Column Grid kartu makanan favorit dengan Rectangle 55 frosted glass dan harga emas
class FavoritScreen extends StatefulWidget {
  final Function(Map<String, dynamic> item)? onSelectFood;
  final VoidCallback? onBack;

  const FavoritScreen({
    super.key,
    this.onSelectFood,
    this.onBack,
  });

  @override
  State<FavoritScreen> createState() => _FavoritScreenState();
}

class _FavoritScreenState extends State<FavoritScreen> {
  final List<Map<String, dynamic>> _favoriteItems = [
    {
      'title': 'Kebab Turki',
      'desc': 'Menggunakan daging unta turki',
      'price': 'Rp 37.000',
      'image': AppAssets.foodKebabTurki,
      'isFav': true,
    },
    {
      'title': 'Nasi Ayam bakar',
      'desc': 'Nasi ayam bakar ayam',
      'price': 'Rp 19.000',
      'image': AppAssets.foodNasiAyam,
      'isFav': true,
    },
    {
      'title': 'Rendang Siujang',
      'desc': 'Rendang khas padang buatan uajang',
      'price': 'Rp 48.000',
      'image': AppAssets.foodRendang,
      'isFav': true,
    },
    {
      'title': 'Bakso Urat',
      'desc': 'Bakso unta bakso dino',
      'price': 'Rp 25.000',
      'image': AppAssets.foodBaksoUrat,
      'isFav': true,
    },
    {
      'title': 'Bakso Urat',
      'desc': 'Bakso unta bakso dino',
      'price': 'Rp 25.000',
      'image': AppAssets.foodBaksoUrat,
      'isFav': true,
    },
    {
      'title': 'Kebab Turki',
      'desc': 'Menggunakan daging unta turki',
      'price': 'Rp 37.000',
      'image': AppAssets.foodKebabTurki,
      'isFav': true,
    },
    {
      'title': 'Nasi Ayam bakar',
      'desc': 'Nasi ayam bakar ayam',
      'price': 'Rp 19.000',
      'image': AppAssets.foodNasiAyam,
      'isFav': true,
    },
  ];

  void _toggleFavorite(int index) {
    setState(() {
      _favoriteItems[index]['isFav'] = !(_favoriteItems[index]['isFav'] == true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header: Gradasi horizontal lavender #9F88FD ke putih presisi Figma node [44:9160]
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF9F88FD),
                  Colors.white,
                ],
                stops: [0.0, 1.0],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 63,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Tombol Back Figma Squircle 34x34
                    Positioned(
                      left: 16,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    // RideOn Logo White presisi Figma (active glyph 60x29 px)
                    Center(
                      child: Image.asset(
                        AppAssets.logoWhite,
                        width: 95,
                        height: 63,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 80),
              children: [
                const FavoritHeader(),

                // 3-Column Grid of Favorite Items (Dimensi 119x152 px presisi Figma)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 10,
                    childAspectRatio: 119 / 152,
                  ),
                  itemCount: _favoriteItems.length,
                  itemBuilder: (context, index) {
                    final item = _favoriteItems[index];
                    return FavoriteCardWidget(
                      item: item,
                      onFavoriteTap: () => _toggleFavorite(index),
                      onTap: () => widget.onSelectFood?.call(item),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
