import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modal dialog sukses verifikasi email sesuai desain Figma (email success ditambahkan.jpg)
class EmailSuccessDialog extends StatelessWidget {
  final String email;
  final bool isUpdate;
  final VoidCallback? onFinished;

  const EmailSuccessDialog({
    super.key,
    required this.email,
    this.isUpdate = false,
    this.onFinished,
  });

  static Future<void> show(
    BuildContext context, {
    required String email,
    bool isUpdate = false,
    VoidCallback? onFinished,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) => EmailSuccessDialog(
        email: email,
        isUpdate: isUpdate,
        onFinished: onFinished,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Amplop dengan Centang (Circular soft-lavender background)
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      size: 38,
                      color: Color(0xFF6B48FC),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6B48FC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Judul Modal
            Text(
              isUpdate
                  ? 'Email Berhasil Diperbarui!'
                  : 'Email Berhasil Ditambahkan!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF17152B),
              ),
            ),
            const SizedBox(height: 10),

            // Deskripsi Penjelasan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Alamat email baru Anda telah berhasil diverifikasi dan terhubung ke akun RideOn.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF17152B).withValues(alpha: 0.7),
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol SELESAI
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onFinished != null) {
                    onFinished!();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B1832),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'SELESAI',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
