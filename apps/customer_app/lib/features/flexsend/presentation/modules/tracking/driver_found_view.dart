import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import '../header/flexsend_header.dart';
import 'driver_card_widget.dart';

class DriverFoundView extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onProceed;

  const DriverFoundView({
    super.key,
    required this.onBack,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
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

          // Bottom Sheet Semi-Transparan Konsisten FlexRide (Color 0xFFC6BCFF 85% opacity)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
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
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF828282),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Status Banner: Driver ditemukan!
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF6B48FC), width: 1.2),
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
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Driver ditemukan!',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6B48FC),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Estimasi tiba 3 mnt',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B6680),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Driver Profile Card
                      const DriverCardWidget(),
                      const SizedBox(height: 14),

                      // Button: Lanjutkan Pesanan (Lebar Disesuaikan / Lebih Pendek)
                      Center(
                        child: SizedBox(
                          width: 220,
                          height: 42,
                          child: ElevatedButton(
                            key: const Key('btn_lanjut_driver_ini'),
                            onPressed: onProceed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF17152B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Lanjutkan Pesanan',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}
