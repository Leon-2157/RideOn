import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

/// Halaman Favorit strictly based on Figma node [44:4566]:
/// - Gradient top header with RideOn logo
/// - Search bar "Cari Kembali favorit Mu!"
/// - Hero banner with abstract blob and character
/// - 3-Column Grid of Favorite Food items with heart icons
class FavoritScreen extends StatefulWidget {
  const FavoritScreen({super.key});

  @override
  State<FavoritScreen> createState() => _FavoritScreenState();
}

class _FavoritScreenState extends State<FavoritScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _favoriteItems = [
    {
      'title': 'Kebab Turki',
      'desc': 'Menggunakan daging unta turki',
      'price': 'Rp 37.000',
      'image': AppAssets.foodKebabTurki,
      'isFavorite': true,
    },
    {
      'title': 'Nasi Ayam bakar',
      'desc': 'Nasi ayam bakar ayam',
      'price': 'Rp 19.000',
      'image': AppAssets.foodNasiAyam,
      'isFavorite': true,
    },
    {
      'title': 'Rendang Siujang',
      'desc': 'Rendang khas padang buatan uajang',
      'price': 'Rp 48.000',
      'image': AppAssets.foodRendang,
      'isFavorite': true,
    },
    {
      'title': 'Bakso Urat',
      'desc': 'Bakso unta bakso dino',
      'price': 'Rp 25.000',
      'image': AppAssets.foodBaksoUrat,
      'isFavorite': true,
    },
    {
      'title': 'Bakso Urat Spesial',
      'desc': 'Bakso unta bakso dino',
      'price': 'Rp 25.000',
      'image': AppAssets.foodBaksoUrat,
      'isFavorite': true,
    },
    {
      'title': 'Kebab Turki Premium',
      'desc': 'Menggunakan daging unta turki',
      'price': 'Rp 37.000',
      'image': AppAssets.foodKebabTurki,
      'isFavorite': true,
    },
    {
      'title': 'Nasi Ayam bakar Madu',
      'desc': 'Nasi ayam bakar ayam',
      'price': 'Rp 19.000',
      'image': AppAssets.foodNasiAyam,
      'isFavorite': true,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          // Header with Gradient & Logo
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 48, bottom: 20, left: 16, right: 16),
              decoration: const BoxDecoration(
                gradient: AppColors.splashGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Centered RideOn Logo
                  Image.asset(
                    AppAssets.logoWhite,
                    width: 100,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),

                  // Search Bar "Cari Kembali favorit Mu!"
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: AppColors.dark,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Cari Kembali favorit Mu!',
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Illustration Banner (Abstract Blob + Character)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.35),
                      AppColors.primary.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Makanan Favoritmu ❤️',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pesan ulang menu andalanmu lebih cepat dan praktis.',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: AppColors.dark.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        AppAssets.manConfused,
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Daftar Favorit Tersimpan',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ),
          ),

          // 3-Column Grid of Favorite Items
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _favoriteItems[index];
                  return _buildFavoriteCard(item);
                },
                childCount: _favoriteItems.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.5),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Heart Icon
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 1.35,
                  child: Image.asset(
                    item['image'] as String,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          // Content info
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['desc'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 8,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['price'] as String,
                  style: GoogleFonts.roboto(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
