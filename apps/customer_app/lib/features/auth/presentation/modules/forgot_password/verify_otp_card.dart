import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';
import 'forgot_password_wrapper.dart';

/// Step 2: Form Verifikasi Kode OTP WhatsApp (Figma: verif.png, verif angka.png, verif salah.png)
class VerifyOtpCard extends StatelessWidget {
  final String normalizedPhone;
  final bool hasOtpError;
  final String? errorMessage;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final int resendCountdown;
  final bool isLoading;
  final VoidCallback onVerify;
  final VoidCallback onResendOtp;
  final VoidCallback onBackToLogin;

  const VerifyOtpCard({
    super.key,
    required this.normalizedPhone,
    required this.hasOtpError,
    this.errorMessage,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.resendCountdown,
    required this.isLoading,
    required this.onVerify,
    required this.onResendOtp,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordWrapper(
      children: [
        const ForgotPasswordCircleIcon(icon: Icons.mark_chat_unread_rounded),
        const SizedBox(height: 16),

        Text(
          'Verifikasi WhatsApp',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Masukkan 6 digit kode OTP yang kami kirimkan ke WhatsApp $normalizedPhone.',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 11.5,
            color: AppColors.dark.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),

        // Error alert banner if invalid OTP (verif salah.png)
        if (hasOtpError || errorMessage != null) ...[
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
                    errorMessage ?? 'Kode OTP WhatsApp tidak valid.',
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

        // 6-digit OTP Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (i) {
              return SizedBox(
                width: 38,
                height: 42,
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace &&
                        otpControllers[i].text.isEmpty &&
                        i > 0) {
                      otpFocusNodes[i - 1].requestFocus();
                    }
                  },
                  child: TextField(
                    key: Key('otp_box_$i'),
                    controller: otpControllers[i],
                    focusNode: otpFocusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 1,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 5) {
                        otpFocusNodes[i + 1].requestFocus();
                      } else if (val.isEmpty && i > 0) {
                        otpFocusNodes[i - 1].requestFocus();
                      }
                      if (otpControllers.every((c) => c.text.isNotEmpty)) {
                        onVerify();
                      }
                    },
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),

        // Countdown timer & Resend Button
        if (resendCountdown > 0) ...[
          Text(
            'Kode kadaluarsa dalam 0:${resendCountdown.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: AppColors.dark.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
        ] else ...[
          GestureDetector(
            onTap: isLoading ? null : onResendOtp,
            child: Text(
              'KIRIM ULANG KODE OTP VIA WA',
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B48FC),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),

        // Button: KONFIRMASI / VERIFIKASI
        SizedBox(
          height: 44,
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('btn_verifikasi_otp'),
            onPressed: isLoading ? null : onVerify,
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
                : const Icon(Icons.send_rounded, size: 16),
            label: Text(
              isLoading ? 'MEMVERIFIKASI...' : 'KONFIRMASI',
              style: GoogleFonts.roboto(
                fontSize: 12,
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
