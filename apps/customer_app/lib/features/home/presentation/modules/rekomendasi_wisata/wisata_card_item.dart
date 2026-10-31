import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';
import 'wisata_item_model.dart';

/// Kartu wisata tunggal — vertikal, hero image full-width + badge Bestseller.
/// Desain presisi Figma node [1:96] / Group 119.
///
/// Widget ini hanya bertanggung jawab atas TAMPILAN.
class WisataCardItem extends StatelessWidget {
  final WisataItemModel item;
  final VoidCallback? onTap;

  const WisataCardItem({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.divider.withValues(alpha: 0.4),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image full-width + badge Bestseller di pojok kiri atas
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 95,
                    child: Image.asset(
                      item.imageAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (item.isBestseller)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.70),
                              width: 0.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Bestseller',
                            style: GoogleFonts.roboto(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  offset: const Offset(0.5, 0.5),
                                  blurRadius: 1.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Teks: judul + deskripsi lengkap
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.roboto(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      height: 1.35,
                      color: AppColors.dark.withValues(alpha: 0.85),
                    ),
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
