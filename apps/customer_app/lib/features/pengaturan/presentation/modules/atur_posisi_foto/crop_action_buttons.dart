import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Action buttons: BATAL and SELESAI
class CropActionButtons extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onCancel;
  final VoidCallback onFinish;

  const CropActionButtons({
    super.key,
    required this.isProcessing,
    required this.onCancel,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tombol BATAL
        GestureDetector(
          onTap: onCancel,
          child: Container(
            height: 44,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E0EE),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'BATAL',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1832),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),

        // Tombol SELESAI
        GestureDetector(
          onTap: isProcessing ? null : onFinish,
          child: Container(
            height: 44,
            width: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1B1832),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'SELESAI',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
