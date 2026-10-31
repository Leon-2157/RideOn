import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'wisata_card_item.dart';
import 'wisata_item_model.dart';
import 'wisata_section_logic.dart';

export 'wisata_card_item.dart';
export 'wisata_item_model.dart';
export 'wisata_section_logic.dart';

/// Section "Rekomendasi Wisata".
///
/// Logika data dikelola di [WisataSectionLogic].
class RekomendasiWisataSection extends StatelessWidget {
  final List<WisataItemModel>? items;
  final Function(WisataItemModel wisata)? onWisataTap;

  const RekomendasiWisataSection({
    super.key,
    this.items,
    this.onWisataTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayItems = items ?? WisataSectionLogic.defaultWisata;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: ikon 3-pin wisata + "Rekomendasi wisata" presisi Figma node [1:8028] & [1:8059]
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(
            children: [
              Image.asset(
                AppAssets.icWisata,
                width: 14,
                height: 14,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place_rounded, size: 10, color: Color(0xFF17152B)),
                    Transform.translate(
                      offset: const Offset(-3, 0),
                      child: const Icon(Icons.place_rounded, size: 11, color: Color(0xFF17152B)),
                    ),
                    Transform.translate(
                      offset: const Offset(-6, 0),
                      child: const Icon(Icons.place_rounded, size: 10, color: Color(0xFF17152B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Rekomendasi wisata',
                style: GoogleFonts.roboto(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17152B),
                ),
              ),
            ],
          ),
        ),

        // List vertikal kartu wisata
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: displayItems.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, index) {
            final wisata = displayItems[index];
            return WisataCardItem(
              item: wisata,
              onTap: () => onWisataTap?.call(wisata),
            );
          },
        ),
      ],
    );
  }
}
