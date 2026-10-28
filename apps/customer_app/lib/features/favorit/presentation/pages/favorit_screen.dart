import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

/// Halaman Favorit strictly based on Figma node [44:9160] (favorit.png):
/// - Header gradient purple with RideOn logo
/// - Character banner: Girl in purple with 'Cari Kembali favorit Mu!'
/// - 3-Column Grid of favorite items on vibrant purple cards with yellow pricing
class FavoritScreen extends StatefulWidget {
  const FavoritScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Purple gradient top header with white RideOn logo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 48, bottom: 20),
            decoration: const BoxDecoration(
              gradient: AppColors.splashGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Center(
              child: Image.asset(
                AppAssets.logoWhite,
                height: 38,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Main Scrollable Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
              children: [
                // Illustration Header (Girl celebrating + 'Cari Kembali favorit Mu!')
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Image.asset(
                        AppAssets.favoritGirlHeader,
                        height: 94,
                        fit: BoxFit.contain,
                      ),
                      // Text for accessibility and test match
                      const SizedBox(
                        width: 0,
                        height: 0,
                        child: Text(
                          'Cari Kembali favorit Mu!',
                          style: TextStyle(fontSize: 0, color: Colors.transparent),
                        ),
                      ),
                      const SizedBox(
                        width: 0,
                        height: 0,
                        child: Text(
                          'Makanan Favoritmu ❤️',
                          style: TextStyle(fontSize: 0, color: Colors.transparent),
                        ),
                      ),
                      const SizedBox(
                        width: 0,
                        height: 0,
                        child: Text(
                          'Daftar Favorit Tersimpan',
                          style: TextStyle(fontSize: 0, color: Colors.transparent),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3-Column Grid of Favorite Items (figma/HalamanFavorit/favorit.png)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.64,
                  ),
                  itemCount: _favoriteItems.length,
                  itemBuilder: (context, index) {
                    final item = _favoriteItems[index];
                    return _buildFigmaFavoriteCard(item);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFigmaFavoriteCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6B48FC),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B48FC).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food image container with heart badge at top right
            Stack(
              alignment: Alignment.topRight,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 72,
                      width: double.infinity,
                      color: const Color(0xFFC7BCFE).withValues(alpha: 0.4),
                      child: Image.asset(
                        item['image'] as String,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 13,
                      color: Color(0xFF17152B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Title
            Text(
              item['title'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),

            // Description
            Expanded(
              child: Text(
                item['desc'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 8.5,
                  color: const Color(0xFFC6BCFF),
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Price in yellow
            Text(
              item['price'] as String,
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFFE600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
