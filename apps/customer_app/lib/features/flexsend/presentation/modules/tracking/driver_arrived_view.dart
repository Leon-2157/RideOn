import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import '../header/flexsend_header.dart';
import '../models/flexsend_item_model.dart';
import 'driver_card_widget.dart';

class DriverArrivedView extends StatelessWidget {
  final List<FlexSendLocation> locations;
  final VoidCallback onBack;
  final VoidCallback onSeeReceipt;

  const DriverArrivedView({
    super.key,
    this.locations = const [],
    required this.onBack,
    required this.onSeeReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = locations.fold<int>(
      0,
      (sum, loc) => sum + loc.items.length,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),
      body: Stack(
        children: [
          // Background Peta
          Positioned.fill(
            child: Image.asset(
              AppAssets.mapFlexSend,
              fit: BoxFit.cover,
            ),
          ),

          // Header FlexSend Konsisten di bagian atas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FlexSendHeader(
              title: 'FlexSend',
              onBack: onBack,
            ),
          ),

          // Bottom Arrived Card Semi-Transparan Konsisten FlexRide (Color 0xFFC6BCFF 85% opacity)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFC6BCFF).withValues(alpha: 0.85),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle Bar
                      Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF828282),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Status Banner (Green: Driver telah sampai)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4F7DF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                size: 24,
                                color: Color(0xFF1E7E34),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Driver Telah Sampai!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E7E34),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pesanan tiba ($totalItems item) • Temui driver di depan',
                                    style: GoogleFonts.roboto(
                                      fontSize: 11,
                                      color: const Color(0xFF4A4458),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Driver Profile Card
                      const DriverCardWidget(),
                      const SizedBox(height: 12),

                      // Button: Selesai & Lihat Rincian Belanja (Proporsional)
                      Center(
                        child: SizedBox(
                          width: 240,
                          height: 42,
                          child: ElevatedButton(
                            key: const Key('btn_selesai_lihat_rincian'),
                            onPressed: onSeeReceipt,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF17152B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.receipt_long_rounded,
                                    size: 18, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'Lihat Rincian Belanja',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
