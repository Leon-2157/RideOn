import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'package:rideon/features/flexfood/presentation/pages/flexfood_screen.dart';
import 'package:rideon/features/flexride/presentation/pages/flexride_screen.dart';
import 'package:rideon/features/flexsend/presentation/pages/flexsend_screen.dart';

import '../modules/favorite_card/favorite_card_widget.dart';
import '../modules/header/favorit_header.dart';

export '../modules/favorite_card/favorite_card_widget.dart';
export '../modules/header/favorit_header.dart';

/// Halaman Favorit Multi-Layanan (FlexFood, FlexRide, FlexSend)
/// Dilengkapi Segmented Switcher di samping karakter perempuan,
/// Sub-Filter Menu & Restoran untuk FlexFood, serta integrasi langsung rute FlexRide & belanja FlexSend.
class FavoritScreen extends StatefulWidget {
  final Function(Map<String, dynamic> item)? onSelectFood;
  final VoidCallback? onBack;

  const FavoritScreen({super.key, this.onSelectFood, this.onBack});

  @override
  State<FavoritScreen> createState() => _FavoritScreenState();
}

class _FavoritScreenState extends State<FavoritScreen> {
  // 0: FlexFood, 1: FlexRide, 2: FlexSend
  int _selectedServiceIndex = 0;

  // Sub-filter khusus FlexFood (0: Makanan, 1: Minuman, 2: Restoran)
  int _selectedFoodSubFilter = 0;

  // 1. Data Menu Makanan Favorit FlexFood
  final List<Map<String, dynamic>> _favoriteFoodItems = [
    {
      'title': 'Kebab Turki',
      'desc': 'Daging kebab rempah gurih',
      'resto': 'Kebab Turki Istanbul',
      'price': 'Rp 37.000',
      'image': AppAssets.foodKebabTurki,
      'isFav': true,
    },
    {
      'title': 'Nasi Ayam Bakar',
      'desc': 'Ayam bakar madu kecap manis',
      'resto': 'Ayam Madu Solo Juara',
      'price': 'Rp 19.000',
      'image': AppAssets.foodNasiAyam,
      'isFav': true,
    },
    {
      'title': 'Rendang Si Ujang',
      'desc': 'Rendang khas padang otentik',
      'resto': 'Warung Padang Si Ujang',
      'price': 'Rp 48.000',
      'image': AppAssets.foodRendang,
      'isFav': true,
    },
    {
      'title': 'Bakso Urat',
      'desc': 'Bakso sapi urat mantap',
      'resto': 'Bakso Urat Pak De',
      'price': 'Rp 25.000',
      'image': AppAssets.foodBaksoUrat,
      'isFav': true,
    },
    {
      'title': 'Nasi Goreng',
      'desc': 'Nasi goreng telur mata sapi',
      'resto': 'Banku City Resto & Cafe',
      'price': 'Rp 10.000',
      'image': AppAssets.foodNasiGoreng,
      'isFav': true,
    },
    {
      'title': 'Bakso Bakar',
      'desc': 'Bakso bakar kecap pedas',
      'resto': 'Bakso Urat Pak De',
      'price': 'Rp 13.000',
      'image': AppAssets.foodBaksoBakar,
      'isFav': true,
    },
  ];

  // 1b. Data Menu Minuman Favorit FlexFood
  final List<Map<String, dynamic>> _favoriteDrinkItems = [
    {
      'title': 'Es Teh Manis',
      'desc': 'Teh melati segar aroma wangi',
      'resto': 'Banku City Resto & Cafe',
      'price': 'Rp 5.000',
      'image': AppAssets.foodNasiGoreng,
      'isFav': true,
    },
    {
      'title': 'Kopi Gula Aren',
      'desc': 'Espresso susu gula aren asli',
      'resto': 'Banku City Resto & Cafe',
      'price': 'Rp 18.000',
      'image': AppAssets.foodBaksoBakar,
      'isFav': true,
    },
    {
      'title': 'Jus Alpukat Kocok',
      'desc': 'Alpukat mentega cokelat lumer',
      'resto': 'Warung Padang Si Ujang',
      'price': 'Rp 15.000',
      'image': AppAssets.foodRendang,
      'isFav': true,
    },
    {
      'title': 'Es Jeruk Peras',
      'desc': 'Jeruk peras murni dingin segar',
      'resto': 'Ayam Madu Solo Juara',
      'price': 'Rp 8.000',
      'image': AppAssets.foodNasiAyam,
      'isFav': true,
    },
  ];

  // 2. Data Restoran Favorit FlexFood
  final List<Map<String, dynamic>> _favoriteRestaurants = [
    {
      'name': 'Banku City Resto & Cafe',
      'category': 'Aneka Nasi, Bakso, Kebab',
      'rating': '4.9',
      'distance': '1.2 km',
      'duration': '15-20 mnt',
      'image': AppAssets.foodNasiGoreng,
      'badge': 'Super Partner',
      'isFav': true,
    },
    {
      'name': 'Warung Padang Si Ujang',
      'category': 'Rendang Khas Padang, Gulai',
      'rating': '4.8',
      'distance': '2.1 km',
      'duration': '20-25 mnt',
      'image': AppAssets.foodRendang,
      'badge': 'Super Partner',
      'isFav': true,
    },
    {
      'name': 'Bakso Urat Pak De',
      'category': 'Bakso Urat, Bakso Bakar, Mie',
      'rating': '4.9',
      'distance': '0.8 km',
      'duration': '10-15 mnt',
      'image': AppAssets.foodBaksoUrat,
      'badge': 'Terlaris',
      'isFav': true,
    },
  ];

  // 3. Data Lokasi / Rute Favorit FlexRide (Jemput -> Tujuan)
  final List<Map<String, dynamic>> _favoriteRideLocations = [
    {
      'label': 'Rute Rumah - Kantor',
      'pickup': 'Jl. Brawl No. 77, Dewantara',
      'destination': 'Jl. Merdeka Barat No. 12, Lhokseumawe',
      'notes': 'Pagar hitam depan pos satpam',
      'estimate': 'Rp 14.000',
      'distance': '3.4 km',
      'isFav': true,
    },
    {
      'label': 'Rute Rumah - Kampus',
      'pickup': 'Jl. Brawl No. 77, Dewantara',
      'destination': 'Gedung Rektorat Unimal, Reuleuet',
      'notes': 'Tunggu di gerbang utama',
      'estimate': 'Rp 18.000',
      'distance': '5.2 km',
      'isFav': true,
    },
    {
      'label': 'Rute Kos - Cafe Teman',
      'pickup': 'Jl. Medan - B. Aceh No. 40',
      'destination': 'Cafe Kopi Teman, Jl. Darussalam',
      'notes': 'Samping minimarket',
      'estimate': 'Rp 10.000',
      'distance': '2.1 km',
      'isFav': true,
    },
  ];

  // 4. Data Toko Belanja Langganan FlexSend
  final List<Map<String, dynamic>> _favoriteSendLocations = [
    {
      'storeName': 'Pasar Pagi Batuphat',
      'category': 'Sayur Segar, Daging & Bumbu',
      'address': 'Jl. Medan - Banda Aceh, Batuphat',
      'itemsCount': '5 Barang langganan',
      'icon': Icons.shopping_basket_rounded,
      'isFav': true,
    },
    {
      'storeName': 'Apotek Kimia Farma',
      'category': 'Obat Rutin, Vitamin & P3K',
      'address': 'Jl. Perdagangan No. 8',
      'itemsCount': '3 Resep tersimpan',
      'icon': Icons.medical_services_rounded,
      'isFav': true,
    },
  ];

  void _confirmRemoveFavorite({
    required String itemName,
    required VoidCallback onConfirm,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Hapus Favorit',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 310,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Hati Ungu khas RideOn (dengan background lingkaran soft lavender)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EFFF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFDDD5FE),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFF6B48FC),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Judul
                  Text(
                    'Hapus dari Favorit?',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Deskripsi
                  Text(
                    'Item "$itemName" akan dihapus dari daftar favorit tersimpan kamu.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: const Color(0xFF6B6680),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Baris Tombol Sejajar: Batalkan & Hapus
                  Row(
                    children: [
                      // Tombol Batalkan
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(dialogContext).pop(),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2EFFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Batalkan',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B48FC),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Tombol Hapus (Merah Tegas)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            onConfirm();
                          },
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53935)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Hapus',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
          ),
        );
      },
    );
  }

  void _toggleFoodFavorite(int index) {
    final item = _favoriteFoodItems[index];
    final bool isFav = item['isFav'] == true;
    if (isFav) {
      _confirmRemoveFavorite(
        itemName: item['title'] as String? ?? 'Item',
        onConfirm: () {
          setState(() {
            _favoriteFoodItems[index]['isFav'] = false;
          });
        },
      );
    } else {
      setState(() {
        _favoriteFoodItems[index]['isFav'] = true;
      });
    }
  }

  void _toggleDrinkFavorite(int index) {
    final item = _favoriteDrinkItems[index];
    final bool isFav = item['isFav'] == true;
    if (isFav) {
      _confirmRemoveFavorite(
        itemName: item['title'] as String? ?? 'Item',
        onConfirm: () {
          setState(() {
            _favoriteDrinkItems[index]['isFav'] = false;
          });
        },
      );
    } else {
      setState(() {
        _favoriteDrinkItems[index]['isFav'] = true;
      });
    }
  }

  void _toggleRestoFavorite(int index) {
    final resto = _favoriteRestaurants[index];
    final bool isFav = resto['isFav'] == true;
    if (isFav) {
      _confirmRemoveFavorite(
        itemName: resto['name'] as String? ?? 'Restoran',
        onConfirm: () {
          setState(() {
            _favoriteRestaurants[index]['isFav'] = false;
          });
        },
      );
    } else {
      setState(() {
        _favoriteRestaurants[index]['isFav'] = true;
      });
    }
  }

  void _toggleRideFavorite(int index) {
    final ride = _favoriteRideLocations[index];
    final bool isFav = ride['isFav'] == true;
    if (isFav) {
      _confirmRemoveFavorite(
        itemName: ride['label'] as String? ?? 'Rute',
        onConfirm: () {
          setState(() {
            _favoriteRideLocations[index]['isFav'] = false;
          });
        },
      );
    } else {
      setState(() {
        _favoriteRideLocations[index]['isFav'] = true;
      });
    }
  }

  void _toggleSendFavorite(int index) {
    final send = _favoriteSendLocations[index];
    final bool isFav = send['isFav'] == true;
    if (isFav) {
      _confirmRemoveFavorite(
        itemName: send['storeName'] as String? ?? 'Toko',
        onConfirm: () {
          setState(() {
            _favoriteSendLocations[index]['isFav'] = false;
          });
        },
      );
    } else {
      setState(() {
        _favoriteSendLocations[index]['isFav'] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header: Gradasi horizontal lavender #9F88FD ke putih presisi Figma
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF9F88FD), Colors.white],
                stops: [0.0, 1.0],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
                        onTap:
                            widget.onBack ??
                            () => Navigator.of(context).maybePop(),
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

                    // RideOn Logo White
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
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 80),
              children: [
                // Header Karakter Perempuan + Segmented 3 Layanan
                FavoritHeader(
                  selectedServiceIndex: _selectedServiceIndex,
                  onSelectService: (index) {
                    setState(() {
                      _selectedServiceIndex = index;
                    });
                  },
                ),

                // Konten Dinamis Berdasarkan Layanan yang Dipilih
                _buildServiceContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceContent() {
    switch (_selectedServiceIndex) {
      case 0:
        return _buildFlexFoodSection();
      case 1:
        return _buildFlexRideSection();
      case 2:
      default:
        return _buildFlexSendSection();
    }
  }

  // ================= 1. KONTEN FLEXFOOD =================
  Widget _buildFlexFoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-filter: Makanan | Minuman | Restoran
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
          child: Row(
            children: [
              _buildSubFilterChip(
                label: 'Makanan',
                icon: Icons.lunch_dining_rounded,
                isSelected: _selectedFoodSubFilter == 0,
                onTap: () => setState(() => _selectedFoodSubFilter = 0),
              ),
              const SizedBox(width: 8),
              _buildSubFilterChip(
                label: 'Minuman',
                icon: Icons.local_drink_rounded,
                isSelected: _selectedFoodSubFilter == 1,
                onTap: () => setState(() => _selectedFoodSubFilter = 1),
              ),
              const SizedBox(width: 8),
              _buildSubFilterChip(
                label: 'Restoran',
                icon: Icons.storefront_rounded,
                isSelected: _selectedFoodSubFilter == 2,
                onTap: () => setState(() => _selectedFoodSubFilter = 2),
              ),
            ],
          ),
        ),

        // Tampilan Kartu Makanan / Minuman / Restoran
        Transform.translate(
          offset: const Offset(0, -25),
          child: Column(
            children: [
              // Tampilan 0: Menu Makanan (Grid 3-Kolom Ungu Presisi Figma)
              if (_selectedFoodSubFilter == 0) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 10,
                    childAspectRatio: 119 / 152,
                  ),
                  itemCount: _favoriteFoodItems.length,
                  itemBuilder: (context, index) {
                    final item = _favoriteFoodItems[index];
                    return FavoriteCardWidget(
                      item: item,
                      onFavoriteTap: () => _toggleFoodFavorite(index),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FlexFoodScreen(
                              initialState: FlexFoodState.grid,
                              initialFood: item,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ] else if (_selectedFoodSubFilter == 1) ...[
                // Tampilan 1: Menu Minuman (Grid 3-Kolom Ungu Presisi Figma)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 10,
                    childAspectRatio: 119 / 152,
                  ),
                  itemCount: _favoriteDrinkItems.length,
                  itemBuilder: (context, index) {
                    final item = _favoriteDrinkItems[index];
                    return FavoriteCardWidget(
                      item: item,
                      onFavoriteTap: () => _toggleDrinkFavorite(index),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FlexFoodScreen(
                              initialState: FlexFoodState.grid,
                              initialFood: item,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ] else ...[
                // Tampilan 2: Restoran Favorit (List Elegan - Klik untuk Buka Halaman Resto)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _favoriteRestaurants.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final resto = _favoriteRestaurants[index];
                    final bool isFav = resto['isFav'] == true;

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FlexFoodScreen(
                              initialState: FlexFoodState.restaurant,
                              initialRestaurantName: resto['name'] as String,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE8E5F5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo Restoran + Rating di Bawahnya
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    resto['image'] as String,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: Color(0xFFFFB300),
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
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE8FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      resto['badge'] as String,
                                      style: GoogleFonts.roboto(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF6B48FC),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    resto['name'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF17152B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    resto['category'] as String,
                                    style: GoogleFonts.roboto(
                                      fontSize: 10.5,
                                      color: const Color(0xFF6B6680),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.near_me_rounded,
                                        size: 11,
                                        color: Color(0xFF6B48FC),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${resto['distance']} • ${resto['duration']}',
                                        style: GoogleFonts.roboto(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF6B6680),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFav
                                    ? const Color(0xFF6B48FC)
                                    : const Color(0xFFA6A3B3),
                                size: 22,
                              ),
                              onPressed: () => _toggleRestoFavorite(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ================= 2. KONTEN FLEXRIDE =================
  Widget _buildFlexRideSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
          child: Row(
            children: [
              const Icon(
                Icons.route_rounded,
                size: 16,
                color: Color(0xFF6B48FC),
              ),
              const SizedBox(width: 6),
              Text(
                'Rute & Alamat Favoritmu',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17152B),
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -25),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _favoriteRideLocations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final loc = _favoriteRideLocations[index];
              final bool isFav = loc['isFav'] == true;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E5F5), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris Atas: Label Rute + Estimasi Harga + Icon Love
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE8FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.two_wheeler_rounded,
                                size: 13,
                                color: Color(0xFF6B48FC),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                loc['label'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B48FC),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${loc['estimate']} • ${loc['distance']}',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav
                                ? const Color(0xFF6B48FC)
                                : const Color(0xFFA6A3B3),
                            size: 20,
                          ),
                          onPressed: () => _toggleRideFavorite(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Detail Rute: Titik Jemput & Titik Tujuan (Visual Timeline Rapi)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Indikator Garis Jemput ke Tujuan
                        Column(
                          children: [
                            const SizedBox(height: 2),
                            const Icon(
                              Icons.radio_button_checked_rounded,
                              size: 14,
                              color: Color(0xFF6B48FC),
                            ),
                            Container(
                              width: 1.5,
                              height: 24,
                              color: const Color(0xFFDDD5FE),
                            ),
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Color(0xFFFF5252),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),

                        // Teks Jemput & Tujuan
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Lokasi Jemput
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jemput',
                                    style: GoogleFonts.roboto(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B48FC),
                                    ),
                                  ),
                                  Text(
                                    loc['pickup'] as String,
                                    style: GoogleFonts.roboto(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF17152B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Lokasi Tujuan
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tujuan',
                                    style: GoogleFonts.roboto(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFFF5252),
                                    ),
                                  ),
                                  Text(
                                    loc['destination'] as String,
                                    style: GoogleFonts.roboto(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF17152B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Garis Pemisah Halus
                    const Divider(color: Color(0xFFF0EDFB), height: 1),
                    const SizedBox(height: 8),

                    // Catatan & Tombol Pesan Rute Ini
                    Row(
                      children: [
                        const Icon(
                          Icons.sticky_note_2_rounded,
                          size: 13,
                          color: Color(0xFF8C87A0),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Catatan: ${loc['notes']}',
                            style: GoogleFonts.roboto(
                              fontSize: 10.5,
                              color: const Color(0xFF6B6680),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FlexRideScreen(
                                  initialState: FlexRideState.vehicleSelect,
                                  initialPickup: loc['pickup'] as String,
                                  initialDestination:
                                      loc['destination'] as String,
                                  initialNote: loc['notes'] as String,
                                  initialVehicle: 'Flex Motor',
                                  initialVehiclePrice: 14000,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B48FC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Pesan Rute Ini',
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= 3. KONTEN FLEXSEND =================
  Widget _buildFlexSendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
          child: Row(
            children: [
              const Icon(
                Icons.store_mall_directory_rounded,
                size: 16,
                color: Color(0xFF6B48FC),
              ),
              const SizedBox(width: 6),
              Text(
                'Toko Belanja Langganan FlexSend',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17152B),
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -25),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _favoriteSendLocations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final store = _favoriteSendLocations[index];
              final bool isFav = store['isFav'] == true;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E5F5), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE8FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        store['icon'] as IconData,
                        size: 22,
                        color: const Color(0xFF6B48FC),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store['storeName'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            store['category'] as String,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${store['address']} • ${store['itemsCount']}',
                            style: GoogleFonts.roboto(
                              fontSize: 10,
                              color: const Color(0xFF6B6680),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav
                                ? const Color(0xFF6B48FC)
                                : const Color(0xFFA6A3B3),
                            size: 20,
                          ),
                          onPressed: () => _toggleSendFavorite(index),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const FlexSendScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B48FC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Titip',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B48FC) : const Color(0xFFF2EFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6B48FC)
                : const Color(0xFFDDD5FE),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : const Color(0xFF6B48FC),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF17152B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
