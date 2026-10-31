import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import '../header/flexfood_header.dart';

class FoodGridView extends StatelessWidget {
  final VoidCallback onSelectFood;

  const FoodGridView({
    super.key,
    required this.onSelectFood,
  });

  static const List<Map<String, dynamic>> foodItems = [
    {
      'title': 'Bakso Urat',
      'desc': 'Bakso unta bakso dino',
      'price': 'Rp 25.000',
      'image': AppAssets.foodBaksoUrat,
      'fav': false,
    },
    {
      'title': 'Kebab Turki',
      'desc': 'Menggunakan daging unta turki',
      'price': 'Rp 37.000',
      'image': AppAssets.foodKebabTurki,
      'fav': true,
    },
    {
      'title': 'Nasi Ayam bakar',
      'desc': 'Nasi ayam bakar ayam',
      'price': 'Rp 19.000',
      'image': AppAssets.foodNasiAyam,
      'fav': true,
    },
    {
      'title': 'Nasi Goreng',
      'desc': 'Nasi goreng telur mata sapi',
      'price': 'Rp 10.000',
      'image': AppAssets.foodNasiGoreng,
      'fav': false,
    },
    {
      'title': 'Rendang Siujang',
      'desc': 'Rendang khas padang buatan uajang',
      'price': 'Rp 48.000',
      'image': AppAssets.foodRendang,
      'fav': true,
    },
    {
      'title': 'Bakso Bakar',
      'desc': 'Bakso bakar bukan bakso goreng',
      'price': 'Rp 13.000',
      'image': AppAssets.foodBaksoBakar,
      'fav': false,
    },
    {
      'title': 'Burger Daging',
      'desc': 'Burger daging rasa daging',
      'price': 'Rp 19.000',
      'image': AppAssets.foodKebabTurki,
      'fav': true,
    },
    {
      'title': 'Pempek',
      'desc': 'Pempek asli khas Palembang',
      'price': 'Rp 60.000',
      'image': AppAssets.foodRendang,
      'fav': true,
    },
    {
      'title': 'Mie Ayam Mang Joni',
      'desc': 'Mie ayam jantan',
      'price': 'Rp 14.000',
      'image': AppAssets.foodBaksoUrat,
      'fav': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const FlexFoodHeader(title: 'Beranda'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded,
                          size: 16, color: Color(0xFF17152B)),
                      const SizedBox(width: 6),
                      Text(
                        'FlexFood',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Pilihan Terlaris',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: const Color(0xFF6B6680),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3-Column Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: foodItems.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.62,
                    ),
                    itemBuilder: (context, index) {
                      final item = foodItems[index];
                      return GestureDetector(
                        onTap: onSelectFood,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B48FC),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6B48FC)
                                    .withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Food Image + Heart
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      item['image'] as String,
                                      width: double.infinity,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Icon(
                                      (item['fav'] as bool)
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 15,
                                      color: (item['fav'] as bool)
                                          ? Colors.black
                                          : Colors.white,
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
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Description
                              Text(
                                item['desc'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.roboto(
                                  fontSize: 8.5,
                                  color:
                                      Colors.white.withValues(alpha: 0.8),
                                  height: 1.2,
                                ),
                              ),
                              const Spacer(),

                              // Price
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  item['price'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFFE600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
}
