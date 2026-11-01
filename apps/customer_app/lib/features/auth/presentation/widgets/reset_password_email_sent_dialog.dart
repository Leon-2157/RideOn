import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

/// Modal Dialog Tautan Reset Terkirim ke Email
class ResetPasswordEmailSentDialog extends StatelessWidget {
  final String email;

  const ResetPasswordEmailSentDialog({
    super.key,
    required this.email,
  });

  static void show(BuildContext context, {required String email}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResetPasswordEmailSentDialog(email: email),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF1F1FD).withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  offset: const Offset(0, 4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE9FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: Color(0xFF6B48FC),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tautan Reset Terkirim!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kami telah mengirimkan tautan untuk mengatur ulang kata sandi ke:\n$email\n\nSilakan periksa Kotak Masuk (Inbox) atau folder Spam pada Gmail Anda, lalu klik tautan tersebut untuk membuat kata sandi baru.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.dark.withValues(alpha: 0.75),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    key: const Key('btn_kembali_setelah_kirim_email'),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Pop back to LoginScreen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text(
                      'KEMBALI KE HALAMAN MASUK',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

