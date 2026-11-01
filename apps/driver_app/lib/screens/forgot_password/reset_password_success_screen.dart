import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../login_screen.dart';

/// [ResetPasswordSuccessScreen]
/// Layar Berhasil Ubah Kata Sandi Driver sesuai spesifikasi desain Figma:
/// - Figma/HalamanLogin/ubah sandi success.png
class ResetPasswordSuccessScreen extends StatelessWidget {
  final VoidCallback? onLoginNow;

  const ResetPasswordSuccessScreen({
    super.key,
    this.onLoginNow,
  });

  void _handleLoginNow(BuildContext context) {
    if (onLoginNow != null) {
      onLoginNow!();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width > 393 ? 373 : size.width - 20,
                ),
                child: _buildGlassCard(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 34.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: const Color(0xFFF1F1FD).withValues(alpha: 0.60),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                offset: const Offset(0, 4),
                blurRadius: 20.0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              const Text(
                'Berhasil Diubah!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Kata sandi akun Anda telah berhasil diperbarui.\nSilakan masuk menggunakan kata sandi yang baru.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.dark.withValues(alpha: 0.70),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Button: MASUK SEKARANG
              SizedBox(
                height: 42,
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('btn_masuk_sekarang'),
                  onPressed: () => _handleLoginNow(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13.0),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'MASUK SEKARANG',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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
