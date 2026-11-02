import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';

/// Checkbox Syarat & Ketentuan RideOn
class RegisterTermsCheckbox extends StatelessWidget {
  final bool isTermsAgreed;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onTapTerms;

  const RegisterTermsCheckbox({
    super.key,
    required this.isTermsAgreed,
    required this.onTermsChanged,
    required this.onTapTerms,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: LinearGradient(
          begin: const Alignment(-0.94, -0.69),
          end: const Alignment(0.94, 0.78),
          stops: const [0.45, 1.0],
          colors: [
            AppColors.primary.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.20),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              key: const Key('checkbox_terms'),
              value: isTermsAgreed,
              activeColor: AppColors.dark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: onTermsChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              key: const Key('link_syarat_ketentuan'),
              onTap: onTapTerms,
              child: RichText(
                text: TextSpan(
                  text: 'Saya menyetujui ',
                  style: GoogleFonts.roboto(
                    fontSize: 10.5,
                    color: AppColors.dark,
                  ),
                  children: [
                    TextSpan(
                      text: 'Syarat & Ketentuan',
                      style: GoogleFonts.roboto(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        color: AppColors.dark,
                      ),
                    ),
                    const TextSpan(text: ' RideOn.'),
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
