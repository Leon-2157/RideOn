import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import '../modules/activity_card/activity_card_widget.dart';
import 'rangkuman_aktivitas_screen.dart';

export 'rangkuman_aktivitas_screen.dart';

/// Halaman Aktivitas strictly based on Figma node [44:9005]:
/// - Aktivitas.png: List of transaction cards (FlexFood, FlexRide) with dates and prices
/// - Rangkuman Aktivitas.png & rate makanan driver.png: Dedicated full screen receipt & rating
class AktivitasScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const AktivitasScreen({
    super.key,
    this.onBack,
  });

  @override
  State<AktivitasScreen> createState() => _AktivitasScreenState();
}

class _AktivitasScreenState extends State<AktivitasScreen> {
  // 0: Semua, 1: FlexRide, 2: FlexFood, 3: FlexSend
  int _selectedFilterIndex = 0;

  final List<Map<String, dynamic>> _activities = [
    {
      'service': 'FlexFood',
      'title': 'Nasi Goreng Mas Fuad',
      'items': '(1x Nasi goreng + telur mata sapi, 1x Es teh hijau)',
      'price': 'Rp 29.500',
      'date': '28, Sep 2026, 07:21',
      'icon': Icons.fastfood_rounded,
      'driver': 'Gufran Fadlurrahman',
      'vehicle': 'Honda supra | BL67SI',
      'metode': 'Bayar Pakai Cash',
      'foodRating': 5,
      'driverRating': 5,
      'isFav': false,
    },
    {
      'service': 'FlexRide',
      'title': 'Perjalanan Dari Kreung Geukueh ke Kampus Unimal Reulet',
      'semanticTitle': 'Perjalanan Ojek Motor',
      'items': '',
      'price': 'Rp 19.500',
      'date': '15, Jan 2026, 20:21',
      'icon': Icons.sports_motorsports_rounded,
      'driver': 'Pikri Haykal',
      'vehicle': 'Honda Vario 160 | BG 4563 R',
      'metode': 'Bayar Pakai Cash',
      'driverRating': 5,
      'isFav': true,
      'pickup': 'Jl. Medan - B. Aceh, Krueng Geukueh',
      'destination': 'Kampus Unimal Reuleuet, Gedung Rektorat',
      'notes': 'Tunggu di gerbang',
    },
    {
      'service': 'FlexSend',
      'title': 'Titip Belanja di Pasar Pagi Batuphat',
      'semanticTitle': 'Titip Belanja & Pengantaran',
      'items': '5 Barang belanjaan',
      'price': 'Rp 22.000',
      'date': '10, Jan 2026, 09:15',
      'icon': Icons.local_shipping_rounded,
      'driver': 'Luthfi Fadil',
      'vehicle': 'Honda Beat | BK 789 M',
      'metode': 'Bayar Pakai E-Wallet',
      'driverRating': 5,
      'isFav': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header gradient horizontal lavender (#9F88FD) ke putih (#FFFFFF) presisi Figma node [44:9005]
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9F88FD),
                  Color(0xFFBAA7FD),
                  Color(0xFFEFEAFF),
                  Color(0xFFFFFFFF),
                ],
                stops: [0.0, 0.45, 0.85, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 63,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Tombol Back Figma Squircle 34x34 persis seperti di header favorit
                    Positioned(
                      left: 16,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onBack ??
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

                    // Centered RideOn Logo
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

          // Filter Segmented Chips (Semua | FlexRide | FlexFood | FlexSend)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterTab(0, 'Semua', Icons.all_inclusive_rounded),
                  const SizedBox(width: 8),
                  _buildFilterTab(1, 'FlexRide', Icons.sports_motorsports_rounded),
                  const SizedBox(width: 8),
                  _buildFilterTab(2, 'FlexFood', Icons.lunch_dining_rounded),
                  const SizedBox(width: 8),
                  _buildFilterTab(3, 'FlexSend', Icons.local_shipping_rounded),
                ],
              ),
            ),
          ),

          // Activities List
          Expanded(
            child: Builder(
              builder: (context) {
                final filteredActivities = _activities.where((act) {
                  if (_selectedFilterIndex == 1) return act['service'] == 'FlexRide';
                  if (_selectedFilterIndex == 2) return act['service'] == 'FlexFood';
                  if (_selectedFilterIndex == 3) return act['service'] == 'FlexSend';
                  return true;
                }).toList();

                if (filteredActivities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 48, color: const Color(0xFFDDD5FE)),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada riwayat pesanan',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B6680),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  itemCount: filteredActivities.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final act = filteredActivities[index];
                    final bool isFav = act['isFav'] == true;
                    return ActivityCardWidget(
                      activity: act,
                      onToggleFavorite: () {
                        setState(() {
                          act['isFav'] = !isFav;
                        });
                      },
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                RangkumanAktivitasScreen(activity: act),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(int index, String title, IconData icon) {
    final bool isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF6B48FC),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
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
