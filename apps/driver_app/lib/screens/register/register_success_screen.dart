import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// [RegisterSuccessScreen]
/// Layar Berkas Berhasil Di Upload sesuai spesifikasi desain Figma:
/// - Figma/HalamanLogin/Berkas berhasil di lengkapi.png
class RegisterSuccessScreen extends StatelessWidget {
  final VoidCallback? onCheckEmail;
  final VoidCallback? onHelpWhatsApp;

  const RegisterSuccessScreen({
    super.key,
    this.onCheckEmail,
    this.onHelpWhatsApp,
  });

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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width > 393 ? 373 : size.width - 24,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 36.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(24.0),
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
                          const SizedBox(height: 12),
                          // Judul: BERKAS BERHASIL DI UPLOAD
                          const Text(
                            'BERKAS BERHASIL DI UPLOAD',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dark,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Deskripsi Validasi Berkas
                          Text(
                            'Tim operasional sedang memvalidasi Keaslian Berkas Anda.\nProses aktivasi radar memakan waktu 1x24 jam.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              height: 1.45,
                              color: AppColors.dark.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Tombol: CEK EMAIL SEKARANG
                          SizedBox(
                            height: 44,
                            width: double.infinity,
                            child: ElevatedButton(
                              key: const Key('btn_cek_email'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.dark,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                if (onCheckEmail != null) {
                                  onCheckEmail!();
                                } else {
                                  Navigator.of(context).popUntil(
                                    (route) => route.isFirst,
                                  );
                                }
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.login_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'CEK EMAIL SEKARANG',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Link Bantuan WhatsApp
                          GestureDetector(
                            key: const Key('link_bantuan_cs_wa'),
                            onTap: onHelpWhatsApp ??
                                () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Menghubungi Tim CS WhatsApp RideOn (+62 812-3456-7890)...',
                                      ),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                },
                            child: const Text(
                              'Bantuan Pendaftaran Mitra (CS WhatsApp)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
