import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';

class FlexRideHeader extends StatelessWidget {
  final VoidCallback onBack;

  const FlexRideHeader({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 32, bottom: 10, left: 14, right: 14),
      decoration: const BoxDecoration(
        gradient: AppColors.splashGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Beranda',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title
          Text(
            'Pesan FlexRide',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
