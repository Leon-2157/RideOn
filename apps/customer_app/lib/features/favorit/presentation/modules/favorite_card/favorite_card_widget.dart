import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kartu item favorit 3-kolom presisi Figma node [44:9160] (favorit.png):
/// - Dimensi: lebar 119px, tinggi 156px, sudut bulat 15px, warna ungu solid #7254F0
/// - Drop shadow halus: #17152B alpha 18%, blur 10, offset 0, 4
/// - Kotak foto makanan Rectangle 55 (109x98 px, radius 10px, border putih 0.5px):
///   * LinearGradient putih murni (top-right) ke putih transparan 0% (bottom-left)
///   * Bayangan 3D oval lembut di bawah foto makanan
///   * Ikon hati favorit warna HITAM SOLID #17152B (bukan merah)
/// - Detail teks di bawah kotak foto (padat, rapi, dan seimbang):
///   * Judul: Roboto Bold 700, 10.5 sp, putih solid
///   * Keterangan: Roboto Regular 400, 8.0 sp, putih 90% opacity
///   * Harga: Roboto Bold 700, 11.5 sp, kuning emas #FFD700 di kanan bawah
class FavoriteCardWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;

  const FavoriteCardWidget({
    super.key,
    required this.item,
    this.onFavoriteTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFav = item['isFav'] == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF7254F0),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF17152B).withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Kotak gambar makanan Rectangle 55 (109x97 proporsional, radius 10)
            Padding(
              padding: const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 0.0),
              child: AspectRatio(
                aspectRatio: 109 / 97,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.50),
                      width: 0.5,
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.white,
                        Color(0x00FFFFFF), // 0% opacity transparan
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Bayangan oval kontak 3D di bawah makanan
                      Positioned(
                        bottom: 8,
                        left: 15,
                        right: 15,
                        height: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.elliptical(35, 5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 2.0,
                          ),
                          child: Image.asset(
                            item['image'] as String,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onFavoriteTap,
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 13,
                              color: const Color(0xFF17152B), // Hitam solid Figma
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Area Teks: Terisi padat proporsional & aman dari overflow
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6.0, 2.0, 6.0, 2.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                            maxWidth: constraints.maxWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.roboto(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 1.0),
                                  Text(
                                    item['desc'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.roboto(
                                      fontSize: 8.0,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withValues(alpha: 0.90),
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  item['price'] as String,
                                  style: GoogleFonts.roboto(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFFD700),
                                    height: 1.10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
