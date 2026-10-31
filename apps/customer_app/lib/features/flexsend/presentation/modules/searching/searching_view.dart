import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';

class FlexSendSearchingView extends StatelessWidget {
  final AnimationController radarController;
  final int totalBayar;
  final VoidCallback onCancel;
  final VoidCallback onDriverFound;

  const FlexSendSearchingView({
    super.key,
    required this.radarController,
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
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.mapFlexSend,
              fit: BoxFit.cover,
            ),
          ),

          // Radar circle overlay
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
                            alpha: (1.0 - radarController.value) * 0.35),
                        border: Border.all(
                          color: const Color(0xFF6B48FC).withValues(
                              alpha: (1.0 - radarController.value) * 0.8),
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
                            alpha: (1.0 - radarController.value) * 0.45),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: onDriverFound,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: const BoxDecoration(
                  color: Color(0xFFC7BCFE),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.radar_rounded,
                            size: 26, color: Color(0xFF6B48FC)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mencari Driver...',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mencari Driver yang aktif dan bersedia!',
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Titip Belanja Pasar Pagi Batuphat Rp ${_formatRupiah(totalBayar)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      key: const Key('btn_batal_cari_driver'),
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE83535)),
                        foregroundColor: const Color(0xFFE83535),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'BATALKAN PEMESANAN',
                        style: GoogleFonts.roboto(
                            fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
