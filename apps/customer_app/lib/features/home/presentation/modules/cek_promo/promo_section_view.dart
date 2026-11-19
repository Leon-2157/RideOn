import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'package:rideon/core/services/customer_api_service.dart';
import 'promo_card_item.dart';
import 'promo_item_model.dart';
import 'promo_logic.dart';

export 'promo_card_item.dart';
export 'promo_item_model.dart';
export 'promo_logic.dart';

/// Section "Cek promo sekarang" — header ikon diskon + carousel banner horizontal.
class CekPromoSection extends StatefulWidget {
  final List<PromoItemModel>? items;
  final Function(PromoItemModel promo)? onPromoTap;

  const CekPromoSection({
    super.key,
    this.items,
    this.onPromoTap,
  });

  @override
  State<CekPromoSection> createState() => _CekPromoSectionState();
}

class _CekPromoSectionState extends State<CekPromoSection> {
  late List<PromoItemModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List<PromoItemModel>.from(
      widget.items ?? PromoLogic.defaultPromos,
    );
    _loadLivePromotions();
  }

  Future<void> _loadLivePromotions() async {
    if (widget.items != null || !CustomerApiService().hasSession) return;
    try {
      final promos = await CustomerApiService().getPromotions();
      if (!mounted || promos.isEmpty) return;
      final fallbacks = PromoLogic.defaultPromos;
      setState(() {
        _items = List.generate(promos.length, (i) {
          final p = promos[i];
          return PromoItemModel(
            imageAsset: fallbacks[i % fallbacks.length].imageAsset,
            title: p.title,
            voucherCode: p.code,
          );
        });
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = widget.items ?? _items;

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
                onTap: () {
                  if (widget.onPromoTap != null) {
                    widget.onPromoTap!(promo);
                  } else if (promo.voucherCode != null &&
                      promo.voucherCode!.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Kode Promo ${promo.voucherCode}: ${promo.title ?? ""}',
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
