import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

/// Halaman Aktivitas strictly based on Figma node [44:9005]:
/// - Gradient top header with RideOn logo & title "Aktivitas"
/// - List of transaction cards (FlexFood, FlexRide) with dates, prices, status
/// - Interactive digital receipt modal (Rangkuman Aktivitas)
class AktivitasScreen extends StatelessWidget {
  const AktivitasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      {
        'service': 'FlexFood',
        'title': 'Nasi Goreng Mas Fuad',
        'items': '1x Nasi goreng + telur mata sapi, 1x Es teh hijau',
        'price': 'Rp 29.500',
        'date': '28, Sep 2026, 07:21',
        'status': 'Selesai',
        'icon': Icons.restaurant_rounded,
        'driver': 'Fikri Haykal',
        'metode': 'RideOn Pay',
      },
      {
        'service': 'FlexRide',
        'title': 'Perjalanan Ojek Motor',
        'items': 'Perjalanan Dari Kreung Geukueh ke Kampus Unimal Reulet',
        'price': 'Rp 19.500',
        'date': '15, Jan 2026, 20:21',
        'status': 'Selesai',
        'icon': Icons.two_wheeler_rounded,
        'driver': 'Pikri Haykal (BG 4563 R)',
        'metode': 'Tunai',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          // Gradient Header with RideOn Logo
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 48, bottom: 22, left: 16, right: 16),
              decoration: const BoxDecoration(
                gradient: AppColors.splashGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    AppAssets.logoWhite,
                    width: 100,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Riwayat Aktivitas',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                'Transaksi Terakhir',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ),
          ),

          // Activities List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final act = activities[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: _buildActivityCard(context, act),
                  );
                },
                childCount: activities.length,
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

  Widget _buildActivityCard(BuildContext context, Map<String, dynamic> act) {
    final isFood = act['service'] == 'FlexFood';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.6),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showReceiptModal(context, act),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Icon Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isFood
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.secondary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    act['icon'] as IconData,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            act['title'] as String,
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              act['status'] as String,
                              style: GoogleFonts.roboto(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        act['items'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 10.5,
                          height: 1.3,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            act['date'] as String,
                            style: GoogleFonts.roboto(
                              fontSize: 9.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            act['price'] as String,
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
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
        ),
      ),
    );
  }

  void _showReceiptModal(BuildContext context, Map<String, dynamic> act) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Rangkuman Aktivitas',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _receiptRow('Layanan', act['service'] as String),
              _receiptRow('Rincian', act['title'] as String),
              _receiptRow('Driver', act['driver'] as String),
              _receiptRow('Tanggal', act['date'] as String),
              _receiptRow('Metode Bayar', act['metode'] as String),
              const Divider(height: 24),
              _receiptRow('Total Bayar', act['price'] as String, isTotal: true),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tutup Rangkuman'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _receiptRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: isTotal ? 13 : 12,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              color: isTotal ? AppColors.dark : AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: isTotal ? AppColors.primary : AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}
