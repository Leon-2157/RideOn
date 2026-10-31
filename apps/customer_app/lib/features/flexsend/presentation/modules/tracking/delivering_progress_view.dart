import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import '../header/flexsend_header.dart';
import 'driver_card_widget.dart';

class DeliveringProgressView extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onAdvanceToArrived;

  const DeliveringProgressView({
    super.key,
    required this.onBack,
    required this.onAdvanceToArrived,
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

          // Bottom Delivering Card
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
                  // Status Banner (Green: Menuju rumah anda)
                  GestureDetector(
                    key: const Key('banner_menuju_rumah'),
                    onTap: onAdvanceToArrived,
                    child: Container(
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Belanja selesai, menuju rumah anda!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E7E34),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Estimasi tiba: 8-12 menit (Jarak 2.1 km)',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10.5,
                                    color: const Color(0xFF1E7E34),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: Color(0xFF1E7E34)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Info Box
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

                  // Driver Card
                  const DriverCardWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
