import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';

import '../../../../home/presentation/modules/pilihan_terlaris/food_card_item.dart';
import '../../../../home/presentation/modules/pilihan_terlaris/food_item_model.dart';
import '../header/flexfood_header.dart';
import '../leaderboard/top20_leaderboard_sheet.dart';

class FoodGridView extends StatefulWidget {
  final Function(Map<String, dynamic> food) onSelectFood;
  final VoidCallback? onSelectResto;
  final VoidCallback? onBack;

  const FoodGridView({
    super.key,
    required this.onSelectFood,
    this.onSelectResto,
    this.onBack,
  });

  @override
  State<FoodGridView> createState() => _FoodGridViewState();
}

class _FoodGridViewState extends State<FoodGridView> {
  int _selectedTabIndex = 0; // 0: Semua, 1: Menu Makanan, 2: Restoran
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  static final List<Map<String, dynamic>> allFoodItems = [
    {
      'title': 'Bakso Urat',
      'desc': 'Bakso unta bakso dino',
      'price': 'Rp 25.000',
      'priceInt': 25000,
      'rating': '4.9',
      'image': AppAssets.foodBaksoUrat,
      'resto': 'Bakso Urat Pak De',
      'distance': '0.8 km',
      'fav': false,
    },
    {
      'title': 'Kebab Turki',
      'desc': 'Menggunakan daging unta turki',
      'price': 'Rp 37.000',
      'priceInt': 37000,
      'rating': '4.8',
      'image': AppAssets.foodKebabTurki,
      'resto': 'Kebab Turki Istanbul',
      'distance': '1.9 km',
      'fav': true,
    },
    {
      'title': 'Nasi Ayam Bakar',
      'desc': 'Nasi ayam bakar ayam madu',
      'price': 'Rp 19.000',
      'priceInt': 19000,
      'rating': '4.9',
      'image': AppAssets.foodNasiAyam,
      'resto': 'Ayam Madu Solo Juara',
      'distance': '2.5 km',
      'fav': true,
    },
    {
      'title': 'Nasi Goreng',
      'desc': 'Nasi goreng telur mata sapi',
      'price': 'Rp 10.000',
      'priceInt': 10000,
      'rating': '4.8',
      'image': AppAssets.foodNasiGoreng,
      'resto': 'Banku City Resto & Cafe',
      'distance': '1.2 km',
      'fav': false,
    },
    {
      'title': 'Rendang Si Ujang',
      'desc': 'Rendang khas padang buatan ujang',
      'price': 'Rp 48.000',
      'priceInt': 48000,
      'rating': '4.9',
      'image': AppAssets.foodRendang,
      'resto': 'Warung Padang Si Ujang',
      'distance': '2.1 km',
      'fav': true,
    },
    {
      'title': 'Bakso Bakar',
      'desc': 'Bakso bakar bukan bakso goreng',
      'price': 'Rp 13.000',
      'priceInt': 13000,
      'rating': '4.7',
      'image': AppAssets.foodBaksoBakar,
      'resto': 'Bakso Urat Pak De',
      'distance': '0.8 km',
      'fav': false,
    },
    {
      'title': 'Burger Daging',
      'desc': 'Burger daging rasa daging',
      'price': 'Rp 19.000',
      'priceInt': 19000,
      'rating': '4.8',
      'image': AppAssets.foodKebabTurki,
      'resto': 'Banku City Resto & Cafe',
      'distance': '1.2 km',
      'fav': true,
    },
    {
      'title': 'Pempek Palembang',
      'desc': 'Pempek asli khas Palembang',
      'price': 'Rp 60.000',
      'priceInt': 60000,
      'rating': '4.9',
      'image': AppAssets.foodRendang,
      'resto': 'Pempek Cek Molek',
      'distance': '1.5 km',
      'fav': true,
    },
    {
      'title': 'Mie Ayam Mang Joni',
      'desc': 'Mie ayam jantan lezat',
      'price': 'Rp 14.000',
      'priceInt': 14000,
      'rating': '4.7',
      'image': AppAssets.foodBaksoUrat,
      'resto': 'Bakso & Mie Mang Joni',
      'distance': '1.0 km',
      'fav': false,
    },
  ];

  static const List<Map<String, dynamic>> menuCategories = [
    {'name': 'Semua', 'icon': Icons.lunch_dining_rounded},
    {'name': 'Terlaris', 'icon': Icons.local_fire_department_rounded},
    {'name': 'Promo', 'icon': Icons.discount_rounded},
    {'name': 'Ayam & Nasi', 'icon': Icons.rice_bowl_rounded},
    {'name': 'Bakso & Mie', 'icon': Icons.ramen_dining_rounded},
    {'name': 'Cepat Saji', 'icon': Icons.fastfood_rounded},
  ];

  static const List<Map<String, dynamic>> restoCategories = [
    {'name': 'Semua Resto', 'icon': Icons.storefront_rounded},
    {'name': 'Terdekat', 'icon': Icons.near_me_rounded},
    {'name': 'Super Partner', 'icon': Icons.verified_rounded},
    {'name': 'Bintang 4.8+', 'icon': Icons.star_rounded},
    {'name': 'Gratis Ongkir', 'icon': Icons.local_shipping_rounded},
    {'name': 'Promo Diskon', 'icon': Icons.percent_rounded},
  ];

  static const List<Map<String, dynamic>> promoBanners = [
    {
      'image': AppAssets.promo1,
      'title': 'Diskon s/d 60% Setiap Hari',
      'tag': 'Spesial Pengguna Baru',
    },
    {
      'image': AppAssets.promo2,
      'title': 'Gratis Ongkir Sepuasnya',
      'tag': 'Min. Belanja 30rb',
    },
    {
      'image': AppAssets.promo3,
      'title': 'Cashback 50% FlexPay',
      'tag': 'Berlaku Semua Resto',
    },
  ];

  static const List<Map<String, dynamic>> popularRestaurants = [
    {
      'name': 'Banku City Resto & Cafe',
      'category': 'Aneka Nasi, Bakso, Kebab',
      'rating': '4.9',
      'reviews': '1.2k+ rating',
      'distance': '1.2 km',
      'duration': '15-20 mnt',
      'priceRange': 'Rp 10.000 - Rp 48.000',
      'image': AppAssets.foodNasiGoreng,
      'tag': 'Paling Diminati',
      'badge': 'Super Partner',
    },
    {
      'name': 'Warung Padang Si Ujang',
      'category': 'Rendang Khas Padang, Gulai',
      'rating': '4.8',
      'reviews': '850+ rating',
      'distance': '2.1 km',
      'duration': '20-25 mnt',
      'priceRange': 'Rp 15.000 - Rp 60.000',
      'image': AppAssets.foodRendang,
      'tag': 'Rasa Otentik',
      'badge': 'Super Partner',
    },
    {
      'name': 'Bakso Urat & Bakso Bakar Pak De',
      'category': 'Bakso Urat, Bakso Bakar, Mie',
      'rating': '4.9',
      'reviews': '2.5k+ rating',
      'distance': '0.8 km',
      'duration': '10-15 mnt',
      'priceRange': 'Rp 13.000 - Rp 25.000',
      'image': AppAssets.foodBaksoUrat,
      'tag': 'Promo Spesial',
      'badge': 'Terlaris',
    },
    {
      'name': 'Kebab Turki Istanbul Express',
      'category': 'Kebab Daging, Burger, Roti Cane',
      'rating': '4.7',
      'reviews': '640+ rating',
      'distance': '1.9 km',
      'duration': '15-25 mnt',
      'priceRange': 'Rp 19.000 - Rp 37.000',
      'image': AppAssets.foodKebabTurki,
      'tag': 'Diskon 20%',
      'badge': 'Super Partner',
    },
    {
      'name': 'Ayam Bakar Madu Solo Juara',
      'category': 'Nasi Ayam Bakar, Lalapan, Sambal',
      'rating': '4.8',
      'reviews': '1.8k+ rating',
      'distance': '2.5 km',
      'duration': '20-30 mnt',
      'priceRange': 'Rp 19.000 - Rp 35.000',
      'image': AppAssets.foodNasiAyam,
      'tag': 'Gratis Ongkir',
      'badge': 'Super Partner',
    },
  ];

  static final List<Map<String, dynamic>> trendingFoods = [
    {
      'title': 'Bakso Urat',
      'desc': 'Bakso unta bakso dino',
      'price': 'Rp 25.000',
      'priceInt': 25000,
      'rating': '4.9',
      'image': AppAssets.foodBaksoUrat,
      'resto': 'Bakso Urat Pak De',
      'distance': '0.8 km',
      'fav': false,
    },
    {
      'title': 'Kebab Turki',
      'desc': 'Daging kebab rempah gurih',
      'price': 'Rp 37.000',
      'priceInt': 37000,
      'rating': '4.8',
      'image': AppAssets.foodKebabTurki,
      'resto': 'Kebab Turki Istanbul',
      'distance': '1.9 km',
      'fav': true,
    },
    {
      'title': 'Nasi Ayam Bakar',
      'desc': 'Ayam bakar madu kecap manis',
      'price': 'Rp 19.000',
      'priceInt': 19000,
      'rating': '4.9',
      'image': AppAssets.foodNasiAyam,
      'resto': 'Ayam Madu Solo Juara',
      'distance': '2.5 km',
      'fav': true,
    },
    {
      'title': 'Rendang Si Ujang',
      'desc': 'Daging sapi rempah otentik',
      'price': 'Rp 48.000',
      'priceInt': 48000,
      'rating': '4.9',
      'image': AppAssets.foodRendang,
      'resto': 'Warung Padang Si Ujang',
      'distance': '2.1 km',
      'fav': true,
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
      backgroundColor: const Color(0xFFF9F8FD),
      body: Column(
        children: [
          FlexFoodHeader(title: 'FlexFood', onBack: widget.onBack),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // 1. Search Bar Modern Ala GoFood/ShopeeFood
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2DCFE),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF6B48FC),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                color: const Color(0xFF17152B),
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Mau makan apa hari ini?...',
                                hintStyle: GoogleFonts.roboto(
                                  fontSize: 12.5,
                                  color: const Color(0xFF9E9AA8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Banner Promo Slider
                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: promoBanners.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final banner = promoBanners[index];
                        return Container(
                          width: 270,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  banner['image'] as String,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withValues(alpha: 0.7),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  bottom: 10,
                                  right: 12,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6B48FC),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          banner['tag'] as String,
                                          style: GoogleFonts.roboto(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        banner['title'] as String,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 2. Segmented Mode Switcher (Semua, Menu Makanan, Restoran) Ala GrabFood Tebal & Penuh
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EDFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2D8FF),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTabItem(
                            index: 0,
                            label: 'Semua',
                            icon: Icons.grid_view_rounded,
                          ),
                          _buildTabItem(
                            index: 1,
                            label: 'Menu',
                            icon: Icons.restaurant_rounded,
                          ),
                          _buildTabItem(
                            index: 2,
                            label: 'Restoran',
                            icon: Icons.storefront_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. Category Selector Horizontal Pills (Hanya muncul jika tab Menu atau Restoran dipilih)
                  if (_selectedTabIndex != 0) ...[
                    Builder(
                      builder: (context) {
                        final currentCategories = _selectedTabIndex == 2
                            ? restoCategories
                            : menuCategories;
                        return SizedBox(
                          height: 38,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: currentCategories.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final cat = currentCategories[index];
                              final isSelected = _selectedCategoryIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryIndex = index;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF6B48FC)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF6B48FC)
                                          : const Color(0xFFE2DCFE),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? const Color(0xFF6B48FC)
                                                  .withValues(alpha: 0.25)
                                            : Colors.black.withValues(
                                                alpha: 0.03,
                                              ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        cat['icon'] as IconData,
                                        size: 16,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF6B48FC),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        cat['name'] as String,
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF17152B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                  ] else ...[
                    const SizedBox(height: 6),
                  ],

                  // 4. Section Menu Makanan / Paling Laris (Tampil jika tab Semua atau Menu Makanan)
                  if (_selectedTabIndex == 0 || _selectedTabIndex == 1) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedTabIndex == 1
                                ? 'Daftar Menu Pilihan'
                                : 'Paling Laris Minggu Ini',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          if (_selectedTabIndex == 0)
                            GestureDetector(
                              onTap: () {
                                showTop20LeaderboardSheet(
                                  context: context,
                                  items: allFoodItems,
                                  onSelectFood: widget.onSelectFood,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE8FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.emoji_events_rounded,
                                      size: 13,
                                      color: Color(0xFF6B48FC),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Top 20',
                                      style: GoogleFonts.roboto(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF6B48FC),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    if (_selectedTabIndex == 1) ...[
                      // Tampilan Grid Lengkap Khusus saat Tab 'Menu Makanan' aktif
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: allFoodItems.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.77,
                              ),
                          itemBuilder: (context, index) {
                            final food = allFoodItems[index];
                            final foodItem = FoodItemModel(
                              title: food['title'] as String,
                              description:
                                  food['resto'] as String? ??
                                  (food['desc'] as String? ?? ''),
                              price: food['price'] as String,
                              imageAsset: food['image'] as String,
                              isFavorite: food['fav'] as bool? ?? false,
                            );
                            return FoodCardItem(
                              item: foodItem,
                              onTap: () => widget.onSelectFood(food),
                              onFavoriteTap: () {
                                setState(() {
                                  food['fav'] =
                                      !(food['fav'] as bool? ?? false);
                                  for (final item in trendingFoods) {
                                    if (item['title'] == food['title']) {
                                      item['fav'] = food['fav'];
                                    }
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      // Tampilan Slider Horizontal (Presisi FoodCardItem dari Home Dashboard)
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: trendingFoods.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final food = trendingFoods[index];
                            final foodItem = FoodItemModel(
                              title: food['title'] as String,
                              description:
                                  food['resto'] as String? ??
                                  (food['desc'] as String? ?? ''),
                              price: food['price'] as String,
                              imageAsset: food['image'] as String,
                              isFavorite: food['fav'] as bool? ?? false,
                            );
                            return FoodCardItem(
                              item: foodItem,
                              onTap: () => widget.onSelectFood(food),
                              onFavoriteTap: () {
                                setState(() {
                                  food['fav'] = !(food['fav'] as bool? ?? false);
                                  // Sinkronkan juga jika makanan ada di allFoodItems
                                  for (final item in allFoodItems) {
                                    if (item['title'] == food['title']) {
                                      item['fav'] = food['fav'];
                                    }
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],

                  if (_selectedTabIndex == 0) const SizedBox(height: 22),

                  // 5. Restoran Populer Terdekat (Tampil jika tab Semua atau Restoran)
                  if (_selectedTabIndex == 0 || _selectedTabIndex == 2) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedTabIndex == 2
                                ? 'Semua Mitra Restoran Resmi'
                                : 'Restoran Pilihan di Sekitarmu',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          Text(
                            'Diskon ongkir & estimasi pengantaran tercepat',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: const Color(0xFF6B6680),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // List Restoran
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: popularRestaurants.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final resto = popularRestaurants[index];
                        return GestureDetector(
                          onTap:
                              widget.onSelectResto ??
                              () => widget.onSelectFood(allFoodItems[0]),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFEAE6FC),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Foto Resto / Logo Profil Toko (Rounded Squircle 16px + Verification Badge)
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 84,
                                      height: 84,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F5FF),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: const Color(0xFFE4DCFF),
                                          width: 1.4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6B48FC)
                                                .withValues(alpha: 0.08),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(6.0),
                                            child: Image.asset(
                                              (resto['logo'] ?? resto['image'])
                                                  as String,
                                              width: 72,
                                              height: 72,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Badge Verifikasi Toko Resmi
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF6B48FC),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.verified_rounded,
                                            size: 11,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),

                                // Info Resto
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEDE8FF),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              resto['badge'] as String,
                                              style: GoogleFonts.roboto(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF6B48FC),
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 15,
                                            color: Color(0xFFF1C40F),
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            resto['rating'] as String,
                                            style: GoogleFonts.roboto(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF17152B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        resto['name'] as String,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF17152B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        resto['category'] as String,
                                        style: GoogleFonts.roboto(
                                          fontSize: 11,
                                          color: const Color(0xFF6B6680),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.near_me_rounded,
                                            size: 12,
                                            color: Color(0xFF6B48FC),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            resto['distance'] as String,
                                            style: GoogleFonts.roboto(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF17152B),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.access_time_filled_rounded,
                                            size: 12,
                                            color: Color(0xFF6B6680),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            resto['duration'] as String,
                                            style: GoogleFonts.roboto(
                                              fontSize: 10.5,
                                              color: const Color(0xFF6B6680),
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8F9EE),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              resto['tag'] as String,
                                              style: GoogleFonts.roboto(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF27AE60),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
            _selectedCategoryIndex =
                0; // Reset index kategori ketika berganti tab
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6B48FC) : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6B48FC).withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14.5,
                color: isSelected ? Colors.white : const Color(0xFF6B48FC),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF5A5575),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
