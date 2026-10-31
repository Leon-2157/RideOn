import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';

class DriverSearchingView extends StatelessWidget {
  const DriverSearchingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Color(0xFF6B48FC),
                strokeWidth: 3.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mencari Driver Terdekat...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF17152B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Menghubungkan ke armada terdekat di sekitar Land of Dawn',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
