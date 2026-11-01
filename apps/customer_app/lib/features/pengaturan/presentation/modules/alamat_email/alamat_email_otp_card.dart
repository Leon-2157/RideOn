import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Form Card Step 2: Form Verifikasi 6 Digit OTP Email (Figma: verif.jpg / verif angka.jpg)
class AlamatEmailOtpCard extends StatelessWidget {
  final String targetEmail;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final int countdownSeconds;
  final bool hasOtpError;
  final bool isLoading;
  final VoidCallback onResend;
  final VoidCallback onVerifyAndSave;
  final VoidCallback onBackToForm;
  final VoidCallback? onClearError;

  const AlamatEmailOtpCard({
    super.key,
    required this.targetEmail,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.countdownSeconds,
    required this.hasOtpError,
    required this.isLoading,
    required this.onResend,
    required this.onVerifyAndSave,
    required this.onBackToForm,
    this.onClearError,
  });

  Widget _buildOtpDigitBox(int index) {
    return Container(
      width: 44,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasOtpError
              ? Colors.red
              : otpControllers[index].text.isNotEmpty
                  ? const Color(0xFF6B48FC)
                  : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: otpControllers[index],
          focusNode: otpFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF17152B),
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            onClearError?.call();
            if (value.isNotEmpty) {
              if (index < 5) {
                otpFocusNodes[index + 1].requestFocus();
              } else {
                otpFocusNodes[index].unfocus();
                onVerifyAndSave();
              }
            } else if (value.isEmpty && index > 0) {
              otpFocusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFC7BCFE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Verifikasi Kode OTP Email',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF17152B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kode verifikasi telah dikirim ke $targetEmail',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: const Color(0xFF17152B).withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 22),

          // 6 Digit OTP Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) => _buildOtpDigitBox(index)),
          ),
          const SizedBox(height: 20),

          // Countdown Timer / Kirim Ulang
          if (countdownSeconds > 0)
            Text(
              'Kirim ulang kode dalam 00:${countdownSeconds.toString().padLeft(2, '0')}',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: const Color(0xFF17152B).withValues(alpha: 0.7),
              ),
            )
          else
            InkWell(
              onTap: isLoading ? null : onResend,
              child: Text(
                'Kirim Ulang Kode Verifikasi',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17152B),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Tombol VERIFIKASI & SIMPAN EMAIL
          GestureDetector(
            onTap: isLoading ? null : onVerifyAndSave,
            child: Container(
              height: 46,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1B1832),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'VERIFIKASI & SIMPAN EMAIL',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action: Ganti Email atau Masukkan Ulang Sandi
          InkWell(
            onTap: isLoading ? null : onBackToForm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Ganti Email atau Masukkan Ulang Sandi',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF17152B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
