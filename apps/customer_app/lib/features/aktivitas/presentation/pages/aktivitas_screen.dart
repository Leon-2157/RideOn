import 'package:flutter/material.dart';
import 'package:rideon/core/constants/app_assets.dart';

import '../modules/activity_card/activity_card_widget.dart';
import 'rangkuman_aktivitas_screen.dart';

export 'rangkuman_aktivitas_screen.dart';

/// Halaman Aktivitas strictly based on Figma node [44:9005]:
/// - Aktivitas.png: List of transaction cards (FlexFood, FlexRide) with dates and prices
/// - Rangkuman Aktivitas.png & rate makanan driver.png: Dedicated full screen receipt & rating
class AktivitasScreen extends StatelessWidget {
  const AktivitasScreen({super.key});

  static const List<Map<String, dynamic>> activities = [
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
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Pastel lavender gradient header with centered white RideOn logo
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFB4A5FE),
                  Color(0xFFE2DCFE),
                  Color(0xFFF7F5FF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Image.asset(
                        AppAssets.logoWhite,
                        height: 38,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(
                      width: 0,
                      height: 0,
                      child: Text(
                        'Riwayat Aktivitas',
                        style: TextStyle(
                          fontSize: 0,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Activities List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              itemCount: activities.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final act = activities[index];
                return ActivityCardWidget(
                  activity: act,
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
            ),
          ),
        ],
      ),
    );
  }
}
