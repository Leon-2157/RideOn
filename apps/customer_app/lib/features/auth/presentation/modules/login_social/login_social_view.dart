import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_colors.dart';

/// Tombol Google Sign-In + footer Daftar Sekarang pada halaman Login.
class LoginSocialView extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGoogleLogin;
  final VoidCallback onRegisterTap;

  const LoginSocialView({
    super.key,
    required this.isLoading,
    required this.onGoogleLogin,
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOrDivider(),
        const SizedBox(height: 10),
        _buildGoogleButton(),
        const SizedBox(height: 24),
        _buildFooter(),
      ],
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.dark.withValues(alpha: 0.40),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'ATAU',
            style: GoogleFonts.roboto(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: AppColors.dark,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.dark.withValues(alpha: 0.40),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      height: 42,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3303045E),
            offset: Offset(0, 2),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('btn_google_login'),
          borderRadius: BorderRadius.circular(13.0),
          onTap: isLoading ? null : onGoogleLogin,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AppAssets.googleIcon,
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Lanjutkan Dengan Google',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return GestureDetector(
      key: const Key('link_daftar_sekarang'),
      onTap: onRegisterTap,
      child: RichText(
        text: TextSpan(
          text: 'Belum punya akun? ',
          style: GoogleFonts.roboto(
            fontSize: 9,
            fontWeight: FontWeight.w400,
            color: AppColors.dark,
          ),
          children: [
            TextSpan(
              text: 'Daftar Sekarang',
              style: GoogleFonts.roboto(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

