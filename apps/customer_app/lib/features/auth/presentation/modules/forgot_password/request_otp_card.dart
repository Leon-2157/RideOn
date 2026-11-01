import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';
import 'forgot_password_wrapper.dart';

/// Step 1: Form Permintaan OTP / Link Reset Email (Figma: Lupa kata sandi.png)
class RequestOtpCard extends StatelessWidget {
  final TextEditingController identifierController;
  final bool isEmail;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSendOtp;
  final VoidCallback onBackToLogin;

  const RequestOtpCard({
    super.key,
    required this.identifierController,
    required this.isEmail,
    required this.isLoading,
    this.errorMessage,
    required this.onSendOtp,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordWrapper(
      children: [
        const ForgotPasswordCircleIcon(icon: Icons.key_rounded),
        const SizedBox(height: 16),

        Text(
          'Lupa Kata Sandi?',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masukkan nomor WhatsApp atau alamat email yang terdaftar di akun RideOn Anda.',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 11.5,
            color: AppColors.dark.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Error message banner
        if (errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE83535), width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFE83535),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE83535),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        ForgotPasswordInput(
          controller: identifierController,
          hintText: 'No. WhatsApp / Email',
          prefixIcon: isEmail ? Icons.email_outlined : Icons.person_rounded,
          keyName: 'input_forgot_identifier',
          keyboardType:
              isEmail ? TextInputType.emailAddress : TextInputType.text,
        ),
        const SizedBox(height: 18),

        SizedBox(
          height: 44,
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('btn_kirim_kode_otp'),
            onPressed: isLoading ? null : onSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.dark.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    isEmail ? Icons.mail_outline_rounded : Icons.send_rounded,
                    size: 16,
                  ),
            label: Text(
              isLoading
                  ? 'MEMPROSES...'
                  : (isEmail
                      ? 'KIRIM TAUTAN RESET KE EMAIL'
                      : 'KIRIM KODE OTP'),
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        BackToLoginLink(onTap: onBackToLogin),
      ],
    );
  }
}
