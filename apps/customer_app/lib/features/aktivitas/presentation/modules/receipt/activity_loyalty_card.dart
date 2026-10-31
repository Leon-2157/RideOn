import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';

/// Loyalty and membership card in Activity Summary
class ActivityLoyaltyCard extends StatelessWidget {
  const ActivityLoyaltyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keuntungan buat kamu',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF17152B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6B48FC),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plus',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17152B),
                ),
              ),
              Text(
                'Pasti diskon s.d. 15rb buat FlexFood dan layanan lainnya!',
                style: GoogleFonts.roboto(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
              const Divider(height: 20, color: Color(0xFFE2E8F0)),
              Text(
                'FlexStar',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17152B),
                ),
              ),
              Text(
                'Dapatin benefit premium gratis!',
                style: GoogleFonts.roboto(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
