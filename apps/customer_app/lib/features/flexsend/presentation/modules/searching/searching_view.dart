import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import '../header/flexsend_header.dart';
import '../models/flexsend_item_model.dart';

class FlexSendSearchingView extends StatelessWidget {
  final AnimationController radarController;
  final List<FlexSendLocation> locations;
  final int totalBayar;
  final VoidCallback onCancel;
  final VoidCallback onDriverFound;

  const FlexSendSearchingView({
    super.key,
    required this.radarController,
    required this.locations,
    required this.totalBayar,
    required this.onCancel,
    required this.onDriverFound,
  });

  String _formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final String storeSummary = locations.isNotEmpty
        ? locations.map((e) => e.name).join(', ')
        : 'Pasar Pagi Batuphat';

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

          // Header FlexSend Konsisten dengan fitur lain
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FlexSendHeader(
              title: 'FlexSend',
              onBack: onCancel,
            ),
          ),

          // Radar circle overlay animasi
          Center(
            child: AnimatedBuilder(
              animation: radarController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 220 * radarController.value + 40,
                      height: 220 * radarController.value + 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6B48FC).withValues(
                            alpha: (1.0 - radarController.value) * 0.3),
                        border: Border.all(
                          color: const Color(0xFF6B48FC).withValues(
                              alpha: (1.0 - radarController.value) * 0.7),
                          width: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      width: 130 * radarController.value + 30,
                      height: 130 * radarController.value + 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6B48FC).withValues(
                            alpha: (1.0 - radarController.value) * 0.4),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom Sheet Semi-Transparan Konsisten FlexRide (Color 0xFFC6BCFF 85% opacity)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onDriverFound,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF828282),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Animated Dual Concentric Radar Icon (Seragam dengan FlexRide)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF5B36F5), width: 3),
                          ),
                          child: Center(
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF5B36F5), width: 2.5),
                              ),
                              child: Center(
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5B36F5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          'Mencari Driver...',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E143E),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        Text(
                          'Mencari Driver terdekat untuk belanja di toko pilihan\nMohon tunggu sebentar',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF4A4458),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Summary Info Pill Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Titip Belanja: $storeSummary • Rp ${_formatRupiah(totalBayar)}',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E143E),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Batalkan Pemesanan Button
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onCancel,
                          child: Container(
                            key: const Key('btn_batal_cari_driver'),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE83535)
                                    .withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'BATALKAN PEMESANAN',
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE83535),
                                  letterSpacing: 0.5,
                                ),
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
          ),
        ],
      ),
    );
  }
}
