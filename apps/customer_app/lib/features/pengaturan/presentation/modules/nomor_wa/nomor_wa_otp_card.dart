import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Form Card Step 2: Form Verifikasi 6 Digit OTP WhatsApp
class NomorWaOtpCard extends StatelessWidget {
  final String targetNormalizedPhone;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final int countdownSeconds;
  final bool isLoading;
  final VoidCallback onResend;
  final VoidCallback onVerifyAndSave;
  final VoidCallback onResetToForm;

  const NomorWaOtpCard({
    super.key,
    required this.targetNormalizedPhone,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.countdownSeconds,
    required this.isLoading,
    required this.onResend,
    required this.onVerifyAndSave,
    required this.onResetToForm,
  });

  Widget _buildOtpDigitBox(int index) {
    return Container(
      width: 42,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFDCD7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Center(
        child: TextField(
          controller: otpControllers[index],
          focusNode: otpFocusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: GoogleFonts.poppins(
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC7BCFE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Verifikasi Kode OTP WhatsApp',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF17152B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kode verifikasi telah dikirim ke $targetNormalizedPhone',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 11.5,
              color: const Color(0xFF17152B).withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),

          // 6 Digit Input Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (i) => _buildOtpDigitBox(i)),
          ),
          const SizedBox(height: 20),

          // Countdown & Resend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                countdownSeconds > 0
                    ? 'Kirim ulang kode dalam 00:${countdownSeconds.toString().padLeft(2, '0')}'
                    : 'Belum menerima kode?',
                style: GoogleFonts.roboto(
                  fontSize: 11.5,
                  color: const Color(0xFF17152B),
                ),
              ),
              if (countdownSeconds == 0) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: isLoading ? null : onResend,
                  child: Text(
                    'Kirim Ulang',
                    style: GoogleFonts.roboto(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1832),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),

          // Tombol VERIFIKASI & SIMPAN NOMOR
          GestureDetector(
            onTap: isLoading ? null : onVerifyAndSave,
            child: Container(
              height: 44,
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
                        'VERIFIKASI & SIMPAN NOMOR',
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
          const SizedBox(height: 12),

          // Tombol Ubah Nomor / Kembali ke Step 1
          GestureDetector(
            onTap: onResetToForm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Ganti Nomor atau Masukkan Ulang Sandi',
                style: GoogleFonts.roboto(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF17152B).withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
