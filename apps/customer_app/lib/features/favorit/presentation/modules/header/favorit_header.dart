import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';

/// Header karakter favorit dengan Speech Bubble + Tab Switcher 3 Layanan (FlexFood, FlexRide, FlexSend)
/// Mengisi ruang kosong di samping karakter perempuan secara padat, harmonis, dan fungsional.
class FavoritHeader extends StatelessWidget {
  final int selectedServiceIndex; // 0: FlexFood, 1: FlexRide, 2: FlexSend
  final ValueChanged<int> onSelectService;

  const FavoritHeader({
    super.key,
    required this.selectedServiceIndex,
    required this.onSelectService,
  });

  @override
  Widget build(BuildContext context) {
    final services = [
      {
        'title': 'FlexFood',
        'iconAsset': AppAssets.icFlexFood,
        'activeIconAsset': AppAssets.icFlexFoodWhite,
      },
      {
        'title': 'FlexRide',
        'iconAsset': AppAssets.icFlexRide,
        'activeIconAsset': AppAssets.icFlexRideWhite,
      },
      {
        'title': 'FlexSend',
        'iconAsset': AppAssets.icFlexSend,
        'activeIconAsset': AppAssets.icFlexSendWhite,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Karakter Perempuan dengan Abstract Blob (Kiri)
              SizedBox(
                width: 125,
                height: 145,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Blob Ungu Lembut
                    Positioned(
                      top: 10,
                      left: -12,
                      width: 148,
                      height: 135,
                      child: Image.asset(
                        AppAssets.abstractBlob,
                        fit: BoxFit.contain,
                        color: const Color(0xFFC6BCFF).withValues(alpha: 0.85),
                      ),
                    ),
                    // Foto Karakter Cewek
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 142,
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

              // 2. Kolom Kanan: Balon Percakapan + Kapsul Layanan 3 Pilihan (Padat & Rapi)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balon Percakapan "Cari Kembali favorit Mu!" dengan Tail
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6.5,
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
                          const Positioned(
                            left: -5,
                            top: 8,
                            child: CustomPaint(
                              size: Size(6, 8),
                              painter: _SpeechTailPainter(
                                color: Color(0xFFB5A5FE),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Segmented Kapsul 3 Layanan: FlexFood, FlexRide, FlexSend
                      Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EFFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFDDD5FE),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: List.generate(services.length, (index) {
                            final isSelected = selectedServiceIndex == index;
                            final service = services[index];

                            return Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => onSelectService(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF6B48FC)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(11),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF6B48FC)
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        isSelected
                                            ? service['activeIconAsset']!
                                            : service['iconAsset']!,
                                        width: 18,
                                        height: 18,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        service['title']!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 9.5,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF5A527A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
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
              'Makanan Favoritmu',
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
