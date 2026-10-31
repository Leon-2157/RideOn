import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import '../header/flexsend_header.dart';
import 'driver_card_widget.dart';

class DriverArrivedView extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSeeReceipt;

  const DriverArrivedView({
    super.key,
    required this.onBack,
    required this.onSeeReceipt,
  });

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

          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: FlexSendCircularBackButton(onTap: onBack),
          ),

          // Bottom Arrived Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              decoration: const BoxDecoration(
                color: Color(0xFFC7BCFE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Banner (Green: Driver telah sampai)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4F7DF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF28A745)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 28, color: Color(0xFF28A745)),
                        const SizedBox(width: 12),
                        Text(
                          'Driver telah sampai',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E7E34),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Belanjaan lengkap (5 item) Siapkan uang tunai / E-Wallet',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const DriverCardWidget(),
                  const SizedBox(height: 14),

                  // Button: Selesai dan Lihat Rincian Belanja
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      key: const Key('btn_selesai_lihat_rincian'),
                      onPressed: onSeeReceipt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17152B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Selesai dan Lihat Rincian Belanja',
                        style: GoogleFonts.roboto(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
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
}
