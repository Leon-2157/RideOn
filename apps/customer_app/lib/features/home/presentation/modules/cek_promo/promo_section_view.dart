import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'promo_card_item.dart';
import 'promo_item_model.dart';
import 'promo_logic.dart';

export 'promo_card_item.dart';
export 'promo_item_model.dart';
export 'promo_logic.dart';

/// Section "Cek promo sekarang" — header ikon diskon + carousel banner horizontal.
///
/// Logika data dikelola di [PromoLogic].
class CekPromoSection extends StatelessWidget {
  final List<PromoItemModel>? items;
  final Function(PromoItemModel promo)? onPromoTap;

  const CekPromoSection({
    super.key,
    this.items,
    this.onPromoTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayItems = items ?? PromoLogic.defaultPromos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: ikon promo diskon + "Cek promo sekarang" presisi Figma node [1:7965] & [1:8057]
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              Image.asset(
                AppAssets.icPromo,
                width: 14,
                height: 14,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.local_offer_rounded,
                  size: 14,
                  color: Color(0xFF17152B),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Cek promo sekarang',
                style: GoogleFonts.roboto(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17152B),
                ),
              ),
            ],
          ),
        ),

        // Carousel banner horizontal
        SizedBox(
          height: 130,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: displayItems.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final promo = displayItems[index];
              return PromoCardItem(
                item: promo,
                onTap: () => onPromoTap?.call(promo),
              );
            },
          ),
        ),
      ],
    );
  }
}
