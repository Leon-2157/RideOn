import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../chat/presentation/pages/chat_screen.dart';

/// Halaman FlexFood strictly matching Figma designs in figma/HalamanFlexFood:
/// - masuk flex food.png: 3-column food grid with search/header and favorites
/// - milih makanan.png: Banku City restaurant menu and floating cart
/// - lihat keranjang.png: Food customization bottom sheet
/// - konfirmasi pesanan.png: Checkout & payment confirmation
/// - driver menuju resto.png / pesanan sampai.png: Driver tracking lifecycle
class FlexFoodScreen extends StatefulWidget {
  const FlexFoodScreen({super.key});

  @override
  State<FlexFoodScreen> createState() => _FlexFoodScreenState();
}

enum FlexFoodState {
  grid, // masuk flex food.png
  restaurant, // milih makanan.png
  checkout, // konfirmasi pesanan.png
  tracking, // driver menuju resto.png -> pesanan sampai.png
}

class _FlexFoodScreenState extends State<FlexFoodScreen> {
  FlexFoodState _currentState = FlexFoodState.grid;

  // Customization & Cart state
  int _cartQuantity = 2;
  int _spicyLevel = 3; // 1: Tidak Pedas, 2: Pedas Sedang, 3: Pedas Banget
  bool _extraEgg = true;
  bool _extraCrackers = false;
  final TextEditingController _kitchenNotesController =
      TextEditingController(text: 'Jangan pakai seledri ya mas');

  // Tracking state (0: driver menuju resto, 1: driver menunggu, 2: driver mengantar, 3: pesanan sampai)
  int _trackingStep = 0;

  @override
  void dispose() {
    _kitchenNotesController.dispose();
    super.dispose();
  }

  int get _itemPrice => 10000;
  int get _addonsPrice => (_extraEgg ? 4000 : 0) + (_extraCrackers ? 2000 : 0);
  int get _subtotalPrice => (_itemPrice * _cartQuantity) + _addonsPrice;
  int get _deliveryFee => 8000;
  int get _serviceFee => 2000;
  int get _totalPrice => _subtotalPrice + _deliveryFee + _serviceFee;

  void _showItemCustomizationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final calculatedTotal = (_itemPrice * _cartQuantity) + _addonsPrice;
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Item info
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          AppAssets.foodNasiGoreng,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nasi Goreng Spesial',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Nasi goreng + telur mata sapi',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: const Color(0xFF6B6680),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp 10.000',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE2DCFE)),
                  const SizedBox(height: 14),

                  // Tingkat Kepedasan (Wajib pilih 1)
                  Row(
                    children: [
                      Text(
                        'Tingkat Kepedasan ',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                      Text(
                        '(Wajib pilih 1)',
                        style: GoogleFonts.roboto(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE83535),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSpicyOption(
                    title: 'Level 1 (Tidak Pedas)',
                    isSelected: _spicyLevel == 1,
                    onTap: () => setSheetState(() => _spicyLevel = 1),
                  ),
                  _buildSpicyOption(
                    title: 'Level 2 (Pedas Sedang)',
                    isSelected: _spicyLevel == 2,
                    onTap: () => setSheetState(() => _spicyLevel = 2),
                  ),
                  _buildSpicyOption(
                    title: 'Level 3 (Pedas Banget)',
                    isSelected: _spicyLevel == 3,
                    onTap: () => setSheetState(() => _spicyLevel = 3),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFE2DCFE)),
                  const SizedBox(height: 14),

                  // Tambahan Topping (Opsional)
                  Row(
                    children: [
                      Text(
                        'Tambahan Topping ',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                      Text(
                        '(Opsional)',
                        style: GoogleFonts.roboto(
                          fontSize: 10.5,
                          color: const Color(0xFF6B6680),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildToppingCheckbox(
                    title: 'Tambah Telur Dadar',
                    price: '+Rp 4.000',
                    isSelected: _extraEgg,
                    onChanged: (val) => setSheetState(() => _extraEgg = val ?? false),
                  ),
                  _buildToppingCheckbox(
                    title: 'Ekstra Kerupuk Kaleng',
                    price: '+Rp 2.000',
                    isSelected: _extraCrackers,
                    onChanged: (val) => setSheetState(() => _extraCrackers = val ?? false),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFE2DCFE)),
                  const SizedBox(height: 14),

                  // Catatan Khusus untuk Dapur
                  Text(
                    'Catatan Khusus untuk Dapur',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2DCFE)),
                    ),
                    child: TextField(
                      controller: _kitchenNotesController,
                      style: GoogleFonts.roboto(fontSize: 12, color: const Color(0xFF17152B)),
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Counter & Confirmation Button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EEFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2DCFE)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: () {
                                if (_cartQuantity > 1) {
                                  setSheetState(() => _cartQuantity--);
                                }
                              },
                            ),
                            Text(
                              '$_cartQuantity',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                              onPressed: () {
                                setSheetState(() => _cartQuantity++);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              _currentState = FlexFoodState.checkout;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B1832),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Konfirmasi Pesanan Rp $calculatedTotal',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
        );
      },
    );
  }

  Widget _buildSpicyOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : const Color(0xFFC6BCFF),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFC6BCFF),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.circle, size: 8, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppColors.primary : const Color(0xFF17152B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToppingCheckbox({
    required String title,
    required String price,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            activeColor: AppColors.primary,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : const Color(0xFF17152B),
              ),
            ),
          ),
          Text(
            price,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentState) {
      case FlexFoodState.grid:
        return _buildGridScreen();
      case FlexFoodState.restaurant:
        return _buildRestaurantScreen();
      case FlexFoodState.checkout:
        return _buildCheckoutScreen();
      case FlexFoodState.tracking:
        return _buildTrackingScreen();
    }
  }

  // -------------------------------------------------------------------------
  // 1. Grid Screen (masuk flex food.png)
  // -------------------------------------------------------------------------
  Widget _buildGridScreen() {
    final foodItems = [
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildFlexFoodHeader('Beranda'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF17152B)),
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.62,
                    ),
                    itemBuilder: (context, index) {
                      final item = foodItems[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentState = FlexFoodState.restaurant;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B48FC),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6B48FC).withValues(alpha: 0.25),
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
                                  color: Colors.white.withValues(alpha: 0.8),
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

  // -------------------------------------------------------------------------
  // 2. Restaurant Screen (milih makanan.png)
  // -------------------------------------------------------------------------
  Widget _buildRestaurantScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildFlexFoodHeader(
            '',
            onBack: () => setState(() => _currentState = FlexFoodState.grid),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Restaurant Banner
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppAssets.bankuBanner,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Restaurant Info Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Banku City',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4F7DF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF28A745)),
                              ),
                              child: Text(
                                'Mitra Resmi Terverifikasi',
                                style: GoogleFonts.roboto(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E7E34),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB300)),
                            const SizedBox(width: 4),
                            Text(
                              '4.8',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(250+ ulasan)',
                              style: GoogleFonts.roboto(fontSize: 11, color: const Color(0xFF6B6680)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Diskon 20% & Gratis Ongkir s/d Rp 10.000 (Min. Rp 40rb)',
                          style: GoogleFonts.roboto(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B48FC),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menu Item 1: Nasi Goreng Spesial
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            AppAssets.foodNasiGoreng,
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nasi Goreng Spesial',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Nasi goreng + telur mata sapi',
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  color: const Color(0xFF6B6680),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rp 10.000',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B48FC),
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _showItemCustomizationSheet,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF6B48FC)),
                            foregroundColor: const Color(0xFF6B48FC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          ),
                          child: Text(
                            '+Tambah',
                            style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Menu Item 2: Bakso Urat (Habis)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA6A3B3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            AppAssets.foodBaksoUrat,
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bakso Urat',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD4D4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'HABIS HARI INI',
                                  style: GoogleFonts.roboto(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFD61F1F),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rp 25.000',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B48FC),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF817E91),
                            disabledBackgroundColor: const Color(0xFF817E91),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          ),
                          child: Text(
                            'Habis',
                            style: GoogleFonts.roboto(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Floating Cart Bar (Matching Figma milih makanan.png)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF17152B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$_cartQuantity Pesanan Rp $_subtotalPrice',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentState = FlexFoodState.checkout;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B48FC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Lihat Keranjang',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 3. Checkout Screen (konfirmasi pesanan.png)
  // -------------------------------------------------------------------------
  Widget _buildCheckoutScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildFlexFoodHeader(
            '',
            onBack: () => setState(() => _currentState = FlexFoodState.restaurant),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Diantar ke Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE8FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: Color(0xFF6B48FC),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Diantar ke: Rumah (Jl. Brawl No. 77)',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Catatan: Pagar hitam depan pos satpam',
                                style: GoogleFonts.roboto(
                                  fontSize: 10.5,
                                  color: const Color(0xFF6B6680),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Ubah',
                          style: GoogleFonts.roboto(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6B48FC),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Order Summary Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dapur Banku City',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_cartQuantity}x Nasi Goreng Spesial',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            Text(
                              'Rp $_subtotalPrice',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Level $_spicyLevel ${_extraEgg ? 'Ekstra Telur, ' : ''}Catatan: ${_kitchenNotesController.text}',
                          style: GoogleFonts.roboto(
                            fontSize: 10.5,
                            color: const Color(0xFF6B6680),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => setState(() => _currentState = FlexFoodState.restaurant),
                          child: Text(
                            '+ Tambah Pesanan Lain',
                            style: GoogleFonts.roboto(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6B48FC),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Metode Pembayaran Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metode Pembayaran',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF6B48FC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle, color: Color(0xFF17152B), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Saldo E-Wallet (Rp 185.000)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF17152B),
                                  ),
                                ),
                              ),
                              const Icon(Icons.radio_button_checked, color: Color(0xFF6B48FC), size: 18),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 30),
                              Expanded(
                                child: Text(
                                  'Bayar Tunai ke Driver',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: const Color(0xFF6B6680),
                                  ),
                                ),
                              ),
                              const Icon(Icons.radio_button_unchecked, color: AppColors.divider, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rincian Pembayaran Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rincian Pembayaran',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPriceRow('Subtotal Makanan', 'Rp $_subtotalPrice'),
                        const SizedBox(height: 6),
                        _buildPriceRow('Ongkos Kirim Driver (1.2 km)', 'Rp $_deliveryFee'),
                        const SizedBox(height: 6),
                        _buildPriceRow('Biaya Layanan Aplikasi', 'Rp $_serviceFee'),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFE2DCFE)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Pembayaran',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            Text(
                              'Rp $_totalPrice',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6B48FC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sudah termasuk PPN resto & jaminan higienis',
                          style: GoogleFonts.roboto(fontSize: 10, color: const Color(0xFF6B6680)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Button: Pesan Makanan Sekarang
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentState = FlexFoodState.tracking;
                        _trackingStep = 0;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1832),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Pesan Makanan Sekarang Rp $_totalPrice',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.roboto(fontSize: 11.5, color: const Color(0xFF17152B)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF17152B),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 4. Tracking Screen (driver menuju resto.png / pesanan sampai.png)
  // -------------------------------------------------------------------------
  Widget _buildTrackingScreen() {
    final titles = [
      'Driver Menuju Restoran...',
      'Driver Menunggu Pesanan...',
      'Driver Sedang Mengantar...',
      'Pesanan Telah Sampai...',
    ];

    final descriptions = [
      'Driver (Muhammad Luthfi Fadil) sedang dalam perjalanan ke Dapur Banku City. Estimasi tiba < 5 menit.',
      'Driver telah tiba di restoran. Menunggu makanan selesai dimasak oleh Dapur Banku City.',
      'Driver sedang dalam perjalanan menuju Rumah Anda (Jl. Brawl No. 77). Estimasi tiba 8 menit.',
      'Pesanan #8821 telah tiba di Rumah (Jl. Brawl No.77). Silakan ambil pesanan Anda.',
    ];

    final progressValues = [0.35, 0.65, 0.85, 1.0];

    final isFinished = _trackingStep == 3;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildFlexFoodHeader(
            '',
            onBack: () => setState(() => _currentState = FlexFoodState.checkout),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tracking Card (soft lavender #C7BCFE)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7BCFE),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B48FC).withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // State Icon
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEDE8FF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFinished ? Icons.storefront_rounded : Icons.delivery_dining_rounded,
                            size: 32,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title
                        Text(
                          titles[_trackingStep],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Description
                        Text(
                          descriptions[_trackingStep],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 11.5,
                            color: const Color(0xFF17152B),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressValues[_trackingStep],
                            backgroundColor: const Color(0xFFE2DCFE),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6B48FC)),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Order snippet container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Dapur Banku City 2 Item',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total Rp 38.000 Lunas via E-Wallet',
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF28A745),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Driver Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        // Driver Photo
                        Stack(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF6B48FC), width: 2),
                                image: const DecorationImage(
                                  image: AssetImage(AppAssets.driverLuthfi),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB300)),
                                  Text(
                                    '4.9',
                                    style: GoogleFonts.roboto(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF17152B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Driver details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Muhammad Luthfi Fadil',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B1832),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'BK 789 M',
                                      style: GoogleFonts.roboto(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Honda Vario 160 Hitam',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.roboto(
                                        fontSize: 10,
                                        color: const Color(0xFF6B6680),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Chat button
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF6B48FC)),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const ChatScreen()),
                            );
                          },
                        ),

                        // Call button
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4F7DF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.phone_rounded, color: Color(0xFF28A745), size: 16),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Menghubungi Muhammad Luthfi Fadil...')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Simulation step switcher (Tap to advance tracking step)
                  if (!isFinished)
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _trackingStep = (_trackingStep + 1) % 4;
                          });
                        },
                        icon: const Icon(Icons.fast_forward_rounded, size: 16),
                        label: Text(
                          'Simulasi Langkah (${_trackingStep + 1}/4)',
                          style: GoogleFonts.roboto(fontSize: 11),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Action Button
                  if (isFinished)
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentState = FlexFoodState.grid;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF28A745), width: 1.5),
                        foregroundColor: const Color(0xFF28A745),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'SELESAI',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Menghubungi driver via telepon/chat...')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE83535)),
                        foregroundColor: const Color(0xFFE83535),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'HUBUNGI DRIVER',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Shared Header for FlexFood Screens
  Widget _buildFlexFoodHeader(String title, {VoidCallback? onBack}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB4A5FE),
            Color(0xFFE2DCFE),
            Color(0xFFF7F5FF),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack ?? () => Navigator.of(context).pop(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6E0FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Color(0xFF17152B),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 34),
            ],
          ),
        ),
      ),
    );
  }
}
