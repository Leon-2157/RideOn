import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlexFoodHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const FlexFoodHeader({
    super.key,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF9F88FD),
            Color(0xFFBAA7FD),
            Color(0xFFEFEAFF),
            Color(0xFFFFFFFF),
          ],
          stops: [0.0, 0.45, 0.85, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 63,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Tombol Back Squircle presisi Figma
              Positioned(
                left: 16,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (onBack != null) {
                      onBack!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: Color(0xFF1E143E),
                    ),
                  ),
                ),
              ),

              // Title FlexFood Center Tengah (Horizontal & Vertikal)
              if (title.isNotEmpty)
                Center(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E143E),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
