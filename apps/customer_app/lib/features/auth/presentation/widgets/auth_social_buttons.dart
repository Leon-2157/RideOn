import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

/// Pemisah teks "ATAU" untuk layar Autentikasi
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.8,
            color: AppColors.dark.withValues(alpha: 0.30),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            'ATAU',
            style: GoogleFonts.roboto(
              fontSize: 10.0,
              fontWeight: FontWeight.w600,
              color: AppColors.dark.withValues(alpha: 0.65),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.8,
            color: AppColors.dark.withValues(alpha: 0.30),
          ),
        ),
      ],
    );
  }
}

/// Tombol "Lanjutkan Dengan Google"
class GoogleAuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final Key? buttonKey;

  const GoogleAuthButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 3),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: ElevatedButton(
        key: buttonKey ?? const Key('btn_google_signup'),
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.dark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13.0),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppAssets.googleIcon,
              width: 17,
              height: 17,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.g_mobiledata_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Lanjutkan Dengan Google',
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

