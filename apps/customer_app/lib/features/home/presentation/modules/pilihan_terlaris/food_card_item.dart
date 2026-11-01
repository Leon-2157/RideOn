import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'food_item_model.dart';

/// Kartu makanan tunggal — proporsional, padat rapi tanpa ruang kosong:
/// - Dimensi kartu: 133x172 px, corner radius 15px, warna ungu solid #7254F0, drop shadow lembut
/// - Kotak foto makanan (Rectangle 55): 121x112 px, radius 10px, border putih 0.3px,
///   LinearGradient (top-right murni putih ke bottom-left 10% transparan)
/// - Ikon favorit: #17152B (outline untuk reguler, solid saat aktif)
/// - Detail teks di bawah kotak foto (padat, proporsional, dan mengisi ruang secara optimal):
///   * Judul makanan: Roboto Bold 700, fontSize 12.0px, warna putih solid
///   * Keterangan menu: Roboto Regular 400, fontSize 9.5px, warna putih 90% opacity
///   * Harga menu: Roboto Bold 700, fontSize 12.5px, warna kuning emas #FFD700 di kanan bawah
class FoodCardItem extends StatelessWidget {
  final FoodItemModel item;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;

  const FoodCardItem({
    super.key,
    required this.item,
    this.onFavoriteTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 133,
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
            // 1. Kotak gambar makanan presisi Figma Rectangle 55 (radius 10)
            Padding(
              padding: const EdgeInsets.fromLTRB(6.0, 6.0, 6.0, 0.0),
              child: AspectRatio(
                aspectRatio: 121 / 105,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.50),
                      width: 0.5,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.0), // 0% opacity, gradasi memudar bersih ke ungu
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Bayangan oval realistis di bawah makanan
                      Positioned(
                        bottom: 8,
                        left: 20,
                        right: 20,
                        height: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.elliptical(40, 6)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                          child: Image.asset(
                            item.imageAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onFavoriteTap,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              item.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 15,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Detail Teks: Mengisi ruang secara proporsional dan padat tanpa ruang kosong menganga
            Padding(
              padding: const EdgeInsets.fromLTRB(7.0, 3.0, 8.0, 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 1.5),
                  // Nama Toko dengan Icon Toko
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.90),
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.5),
                  // Baris Bawah: Rating di kiri & Harga di kanan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 12.5,
                            color: Color(0xFFFFD700),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.rating,
                            style: GoogleFonts.roboto(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        item.price,
                        style: GoogleFonts.roboto(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFFD700),
                          height: 1.10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
