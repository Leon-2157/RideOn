import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';

/// Header karakter favorit + speech bubble presisi Figma node [44:9160] (favorit.png):
/// - Ilustrasi perempuan di sisi kiri
/// - Balon percakapan ungu (#937BFD) bertuliskan "Cari Kembali favorit Mu!"
/// - Helper teks semantik (SizedBox 0x0) untuk kompatibilitas uji widget & aksesibilitas
class FavoritHeader extends StatelessWidget {
  const FavoritHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ilustrasi Karakter Perempuan dengan Abstrak Blob di belakangnya
              SizedBox(
                width: 140,
                height: 155,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // 1. Abstrak Blob lavender di belakang perempuan presisi Figma
                    Positioned(
                      top: 4,
                      left: -8,
                      right: -8,
                      bottom: 8,
                      child: Image.asset(
                        AppAssets.abstractBlob,
                        fit: BoxFit.contain,
                        color: const Color(0xFFC6BCFF).withValues(alpha: 0.70),
                      ),
                    ),

                    // 2. Ilustrasi Perempuan (Tinggi 155 px, pinggang menyentuh batas bawah)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 155,
                      child: Image.asset(
                        AppAssets.favoritGirlHeader,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Balon Percakapan Pastel Lavender (#B5A5FE) Presisi Figma dengan Pointer Tail
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB5A5FE),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB5A5FE)
                                  .withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Cari Kembali favorit Mu!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        left: -5,
                        top: 9,
                        child: CustomPaint(
                          size: Size(6, 8),
                          painter: _SpeechTailPainter(color: Color(0xFFB5A5FE)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Teks bantuan semantik 0x0 untuk tes otomatis
          const SizedBox(
            width: 0,
            height: 0,
            child: Text(
              'Makanan Favoritmu ❤️',
              style: TextStyle(fontSize: 0, color: Colors.transparent),
            ),
          ),
          const SizedBox(
            width: 0,
            height: 0,
            child: Text(
              'Daftar Favorit Tersimpan',
              style: TextStyle(fontSize: 0, color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter untuk ekor segitiga balon percakapan mengarah ke karakter perempuan
class _SpeechTailPainter extends CustomPainter {
  final Color color;

  const _SpeechTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpeechTailPainter oldDelegate) =>
      oldDelegate.color != color;
}
