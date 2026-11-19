import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../home/presentation/modules/pilihan_terlaris/food_card_item.dart';
import '../../../../home/presentation/modules/pilihan_terlaris/food_item_model.dart';
import '../../../../../core/services/customer_api_service.dart';
import '../../../data/flexfood_catalog.dart';
import '../header/flexfood_header.dart';
import '../leaderboard/top20_leaderboard_sheet.dart';

class FoodGridView extends StatefulWidget {
  final Function(Map<String, dynamic> food) onSelectFood;
  final VoidCallback? onSelectResto;
  final ValueChanged<String>? onSelectRestaurantName;
  final VoidCallback? onBack;
  final int initialTabIndex;

  const FoodGridView({
    super.key,
    required this.onSelectFood,
    this.onSelectResto,
    this.onSelectRestaurantName,
    this.onBack,
    this.initialTabIndex = 0,
  });

  @override
  State<FoodGridView> createState() => _FoodGridViewState();
}

class _FoodGridViewState extends State<FoodGridView> {
  late int _selectedTabIndex =
      widget.initialTabIndex.clamp(0, 2); // 0: Semua, 1: Menu, 2: Restoran
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allFoodItems = FlexFoodCatalog.createAllFoodItems();
  List<Map<String, dynamic>> _trendingFoods =
      FlexFoodCatalog.createTrendingFoods();

  @override
  void initState() {
    super.initState();
    _loadLiveCatalog();
  }

  Future<void> _loadLiveCatalog() async {
    final api = CustomerApiService();
    if (!api.hasSession) return;
    try {
      final menus = await api.getPublicMenus();
      if (!mounted || menus.isEmpty) return;
      final defaults = FlexFoodCatalog.createAllFoodItems();
      final mapped = List.generate(menus.length, (i) {
        final m = menus[i];
        final formatted = m.price
            .toString()
            .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (x) => '${x[1]}.');
        return <String, dynamic>{
          'menuId': m.id,
          'storeId': m.storeId,
          'title': m.name,
          'desc': m.description.isNotEmpty ? m.description : m.storeName,
          'price': 'Rp $formatted',
          'priceInt': m.price,
          'rating': m.ratingAvg.toStringAsFixed(1),
          'image': m.photoUrl.isNotEmpty
              ? api.resolveUrl(m.photoUrl)
              : defaults[i % defaults.length]['image'],
          'resto': m.storeName,
          'distance': '1.2 km',
          'fav': false,
          'category': m.category,
          'isTrending': i < 4 || m.soldCount > 0,
          'isPromo': true,
        };
      });
      setState(() {
        _allFoodItems = mapped;
        _trendingFoods = mapped.take(4).toList();
      });
    } catch (_) {}
  }

  void _showAiFoodRecommenderSheet() {
    final queryCtrl = TextEditingController();
    String? aiReply;
    bool loading = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> askAi(String q) async {
              final prompt = q.trim();
              if (prompt.isEmpty || loading) return;
              setSheetState(() => loading = true);
              try {
                final reply = await CustomerApiService().aiChat(
                  sessionId: 'food-rec-${DateTime.now().millisecondsSinceEpoch}',
                  message:
                      'Rekomendasikan menu makanan yang cocok untuk permintaan ini berdasarkan data warung RideOn yang buka: "$prompt"',
                );
                if (!ctx.mounted) return;
                setSheetState(() {
                  aiReply = reply;
                  loading = false;
                });
              } catch (e) {
                if (!ctx.mounted) return;
                setSheetState(() {
                  aiReply = 'Gagal memuat rekomendasi AI: $e';
                  loading = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tanya AI Menu RideOn',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tanya menu pedas, hemat, atau warung yang buka saat ini.',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: const Color(0xFF6B6680),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Pedas < Rp 25.000'),
                        onPressed: () {
                          queryCtrl.text = 'Makanan pedas di bawah Rp 25.000 yang warungnya buka';
                          askAi(queryCtrl.text);
                        },
                      ),
                      ActionChip(
                        label: const Text('Favorit Unimal'),
                        onPressed: () {
                          queryCtrl.text = 'Menu terlaris dekat Kampus Bukit Indah';
                          askAi(queryCtrl.text);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: queryCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Cari mie pedas dekat Bukit Indah',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: askAi,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: loading ? null : () => askAi(queryCtrl.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B48FC),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(loading ? '...' : 'Cari'),
                      ),
                    ],
                  ),
                  if (aiReply != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F4FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2DCFE)),
                      ),
                      child: SelectableText(
                        aiReply!,
                        style: const TextStyle(fontSize: 12.5, height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(queryCtrl.dispose);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFavorite(String title) {
    setState(() {
      bool? updatedFav;
      for (final item in _allFoodItems) {
        if (item['title'] == title) {
          updatedFav = !(item['fav'] as bool? ?? false);
          item['fav'] = updatedFav;
        }
      }
      if (updatedFav != null) {
        for (final item in _trendingFoods) {
          if (item['title'] == title) {
            item['fav'] = updatedFav;
          }
        }
      }
    });
  }

  String get _activeMenuCategoryName {
    if (_selectedTabIndex != 1) return 'Semua';
    if (_selectedCategoryIndex < 0 ||
        _selectedCategoryIndex >= FlexFoodCatalog.menuCategories.length) {
      return 'Semua';
    }
    return FlexFoodCatalog.menuCategories[_selectedCategoryIndex]['name']
        as String;
  }

  String get _activeRestoCategoryName {
    if (_selectedTabIndex != 2) return 'Semua Resto';
    if (_selectedCategoryIndex < 0 ||
        _selectedCategoryIndex >= FlexFoodCatalog.restoCategories.length) {
      return 'Semua Resto';
    }
    return FlexFoodCatalog.restoCategories[_selectedCategoryIndex]['name']
        as String;
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final bool isSearching = query.isNotEmpty;

    final filteredAllFoods = FlexFoodCatalog.filterFoods(
      _allFoodItems,
      query: query,
      category: _activeMenuCategoryName,
    );
    final filteredRestaurants = FlexFoodCatalog.filterRestaurants(
      FlexFoodCatalog.popularRestaurants,
      query: query,
      category: _activeRestoCategoryName,
    );

    final bool showFoodsSection =
        _selectedTabIndex == 0 || _selectedTabIndex == 1;
    final bool showRestoSection =
        _selectedTabIndex == 0 || _selectedTabIndex == 2;
    final bool hasAnyMatch =
        (showFoodsSection && filteredAllFoods.isNotEmpty) ||
        (showRestoSection && filteredRestaurants.isNotEmpty);

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

                  // 1. Search Bar Modern Ala GoFood/ShopeeFood (Live Filtering)
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
                              onChanged: (_) => setState(() {}),
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
                          if (isSearching)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xFF8E88A8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        key: const Key('btn_ai_food_recommender'),
                        onPressed: _showAiFoodRecommenderSheet,
                        icon: const Icon(Icons.auto_awesome,
                            size: 16, color: Color(0xFF6B48FC)),
                        label: const Text('Tanya AI Menu'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B48FC),
                          side: const BorderSide(color: Color(0xFFE2DCFE)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Banner Promo Slider (Sembunyikan saat mengetik agar hasil langsung terlihat)
                  if (!isSearching) ...[
                    SizedBox(
                      height: 130,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: FlexFoodCatalog.promoBanners.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final banner = FlexFoodCatalog.promoBanners[index];
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
                  ],

                  // 3. Segmented Mode Switcher (Semua, Menu, Restoran)
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

                  // 4. Category Selector Horizontal Pills
                  if (_selectedTabIndex != 0) ...[
                    Builder(
                      builder: (context) {
                        final currentCategories = _selectedTabIndex == 2
                            ? FlexFoodCatalog.restoCategories
                            : FlexFoodCatalog.menuCategories;
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
                                key: Key('food_cat_${cat['name']}'),
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

                  if (!hasAnyMatch) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 36,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE8FF),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.search_off_rounded,
                                size: 30,
                                color: Color(0xFF6B48FC),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Menu atau restoran tidak ditemukan',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSearching
                                  ? 'Tidak ada hasil untuk "$query". Coba kata kunci lain.'
                                  : 'Tidak ada item pada kategori ini.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: const Color(0xFF6B6680),
                              ),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _selectedCategoryIndex = 0;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B48FC),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Reset Pencarian & Filter',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // 5. Section Menu Makanan / Paling Laris
                  if (showFoodsSection && filteredAllFoods.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isSearching
                                  ? 'Menu Ditemukan (${filteredAllFoods.length})'
                                  : (_selectedTabIndex == 1
                                        ? 'Daftar Menu Pilihan'
                                        : 'Paling Laris Minggu Ini'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                          ),
                          if (_selectedTabIndex == 0 && !isSearching)
                            GestureDetector(
                              onTap: () {
                                showTop20LeaderboardSheet(
                                  context: context,
                                  items: _allFoodItems,
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

                    if (_selectedTabIndex == 1 || isSearching) ...[
                      // Tampilan Grid Lengkap saat Tab 'Menu' aktif atau sedang mencari
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredAllFoods.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.77,
                              ),
                          itemBuilder: (context, index) {
                            final food = filteredAllFoods[index];
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
                              onFavoriteTap: () =>
                                  _toggleFavorite(food['title'] as String),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      // Tampilan Slider Horizontal default di Tab 'Semua'
                      SizedBox(
                        height: 176,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _trendingFoods.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final food = _trendingFoods[index];
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
                              onFavoriteTap: () =>
                                  _toggleFavorite(food['title'] as String),
                            );
                          },
                        ),
                      ),
                    ],
                  ],

                  if (_selectedTabIndex == 0 &&
                      showFoodsSection &&
                      filteredAllFoods.isNotEmpty)
                    const SizedBox(height: 22),

                  // 6. Restoran Populer Terdekat
                  if (showRestoSection && filteredRestaurants.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSearching
                                ? 'Restoran Ditemukan (${filteredRestaurants.length})'
                                : (_selectedTabIndex == 2
                                      ? 'Semua Mitra Restoran Resmi'
                                      : 'Restoran Pilihan di Sekitarmu'),
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
                      itemCount: filteredRestaurants.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final resto = filteredRestaurants[index];
                        return GestureDetector(
                          onTap: () {
                            final name = resto['name'] as String;
                            if (widget.onSelectRestaurantName != null) {
                              widget.onSelectRestaurantName!(name);
                            } else if (widget.onSelectResto != null) {
                              widget.onSelectResto!();
                            } else {
                              widget.onSelectFood(_allFoodItems[0]);
                            }
                          },
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
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFE8F9EE),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  resto['tag'] as String,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        const Color(0xFF27AE60),
                                                  ),
                                                ),
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
