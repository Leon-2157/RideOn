import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'otp_verification_screen.dart';

/// [ForgotPasswordScreen]
/// Layar Lupa Kata Sandi Driver sesuai spesifikasi desain Figma:
/// - Figma/HalamanLogin/Lupa kata sandi.png
/// - Figma/HalamanLogin/Lupa kata sandi-1.png
class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback? onBackToLogin;
  final ValueChanged<String>? onOtpRequested;

  const ForgotPasswordScreen({
    super.key,
    this.onBackToLogin,
    this.onOtpRequested,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _submit() {
    final identifier = _identifierController.text.trim();
    if (widget.onOtpRequested != null) {
      widget.onOtpRequested!(identifier);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            identifier: identifier,
          ),
        ),
      );
    }
  }

  void _handleBack() {
    if (widget.onBackToLogin != null) {
      widget.onBackToLogin!();
    } else {
      Navigator.of(context).pop();
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
                child: _buildGlassCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 26.0),
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
              // Badge Icon Kunci (Key)
              _buildTopBadge(
                child: Transform.rotate(
                  angle: -0.785, // -45 deg rotation
                  child: const Icon(
                    Icons.vpn_key_rounded,
                    size: 20,
                    color: AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Lupa Kata Sandi?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                'Masukkan nomor WhatsApp atau alamat email\nyang terdaftar di akun RideOn Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.dark.withValues(alpha: 0.70),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),

              // Input field: No. WhatsApp / Email
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13.0),
                  gradient: LinearGradient(
                    begin: const Alignment(-0.94, -0.69),
                    end: const Alignment(0.94, 0.78),
                    stops: const [0.45, 1.0],
                    colors: [
                      AppColors.primary.withValues(alpha: 0.20),
                      Colors.white.withValues(alpha: 0.20),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      offset: const Offset(2, 2),
                      blurRadius: 8.0,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 19,
                      color: AppColors.dark,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        key: const Key('input_forgot_identifier'),
                        controller: _identifierController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.dark,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          hintText: 'No. WhatsApp / Email',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: AppColors.dark.withValues(alpha: 0.70),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Button: KIRIM KODE OTP
              SizedBox(
                height: 42,
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('btn_kirim_kode_otp'),
                  onPressed: _submit,
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
                        Icons.send_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'KIRIM KODE OTP',
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
              const SizedBox(height: 24),

              // Kembali ke halaman Masuk
              GestureDetector(
                key: const Key('link_kembali_ke_login'),
                onTap: _handleBack,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: 14,
                      color: AppColors.dark,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Kembali ke halaman Masuk',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBadge({required Widget child}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE2DCFE),
            Color(0xFFC6BCFF),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
