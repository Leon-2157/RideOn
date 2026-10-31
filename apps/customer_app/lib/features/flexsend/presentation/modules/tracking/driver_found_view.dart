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

          // Bottom Sheet
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
                  // Status Banner: Driver ditemukan!
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF6B48FC), width: 1.2),
                    ),
                    child: Text(
                      'Driver ditemukan!',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B48FC),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Driver Profile Card
                  const DriverCardWidget(),
                  const SizedBox(height: 14),

                  // Button: Lanjut dengan driver ini?
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      key: const Key('btn_lanjut_driver_ini'),
                      onPressed: onProceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17152B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Lanjut dengan driver ini?',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
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
