import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';

enum OtpDeliveryMode {
  whatsapp,
  sms,
}

/// View Verifikasi OTP 6 Digit untuk Pendaftaran Akun
class RegisterOtpView extends StatelessWidget {
  final OtpDeliveryMode otpDeliveryMode;
  final String formattedPhone;
  final bool hasOtpError;
  final String otpErrorMessage;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final int resendCountdown;
  final String formattedCountdown;
  final bool isLoading;
  final VoidCallback onResendOtp;
  final VoidCallback onFallbackSms;
  final VoidCallback onVerify;
  final VoidCallback onBackToForm;

  const RegisterOtpView({
    super.key,
    required this.otpDeliveryMode,
    required this.formattedPhone,
    required this.hasOtpError,
    required this.otpErrorMessage,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.resendCountdown,
    required this.formattedCountdown,
    required this.isLoading,
    required this.onResendOtp,
    required this.onFallbackSms,
    required this.onVerify,
    required this.onBackToForm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          otpDeliveryMode == OtpDeliveryMode.whatsapp
              ? 'Verifikasi Nomor WhatsApp'
              : 'Verifikasi Kode OTP SMS',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          otpDeliveryMode == OtpDeliveryMode.whatsapp
              ? 'Masukkan 6 digit kode yang kami kirimkan ke nomor WhatsApp Anda $formattedPhone'
              : 'Masukkan 6 digit kode yang dikirimkan melalui SMS ke nomor $formattedPhone',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.dark.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        // Error Banner OTP (Figma: verif salah.png)
        if (hasOtpError) ...[
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
                    otpErrorMessage,
                    style: GoogleFonts.roboto(
                      fontSize: 10.5,
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

        // 6 Kotak PIN OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) => _buildOtpBox(index)),
        ),
        const SizedBox(height: 18),

        // Countdown Timer & Resend
        if (resendCountdown > 0)
          Text(
            'Kirim ulang kode dalam ($formattedCountdown)',
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.dark.withValues(alpha: 0.7),
            ),
          )
        else
          GestureDetector(
            key: const Key('btn_resend_otp'),
            onTap: isLoading ? null : onResendOtp,
            child: Text(
              'Kirim Ulang Kode',
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Fallback Link / Catatan
        if (otpDeliveryMode == OtpDeliveryMode.whatsapp)
          GestureDetector(
            key: const Key('link_fallback_sms_in_otp'),
            onTap: onFallbackSms,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: 'Tidak menerima kode di WhatsApp? ',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: AppColors.dark.withValues(alpha: 0.8),
                ),
                children: [
                  TextSpan(
                    text: 'Kirim via SMS',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Text(
            'Pastikan nomor Anda aktif untuk menerima SMS.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 10.5,
              color: AppColors.dark.withValues(alpha: 0.65),
            ),
          ),
        const SizedBox(height: 20),

        // Tombol VERIFIKASI
        SizedBox(
          height: 42,
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('btn_verifikasi_otp'),
            onPressed: isLoading ? null : onVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13.0),
              ),
              padding: EdgeInsets.zero,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'VERIFIKASI',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 14),

        // Link Footer: Ubah Nomor Telepon
        GestureDetector(
          key: const Key('btn_back_to_form'),
          onTap: onBackToForm,
          child: Text(
            'Ubah Nomor Telepon',
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.dark.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 44,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
          color: hasOtpError
              ? const Color(0xFFE83535)
              : Colors.white.withValues(alpha: 0.5),
          width: hasOtpError ? 1.5 : 1.0,
        ),
      ),
      child: Center(
        child: TextField(
          key: Key('otp_box_$index'),
          controller: otpControllers[index],
          focusNode: otpFocusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < 5) {
                otpFocusNodes[index + 1].requestFocus();
              } else {
                otpFocusNodes[index].unfocus();
                onVerify();
              }
            } else if (value.isEmpty && index > 0) {
              otpFocusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }
}
