import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';

import 'food_card_item.dart';
import 'food_item_model.dart';
import 'food_section_logic.dart';

export 'food_card_item.dart';
export 'food_item_model.dart';
export 'food_section_logic.dart';

/// Section "FlexFood - Pilihan Terlaris".
///
/// Logika fetching / state dipisahkan di [FoodSectionLogic].
/// Section ini menampilkan header cutlery + list horizontal kartu makanan ungu presisi Figma node [1:8063].
class PilihanTerlarisSection extends StatefulWidget {
  final List<FoodItemModel>? items;
  final Function(FoodItemModel item)? onFoodTap;

  const PilihanTerlarisSection({super.key, this.items, this.onFoodTap});

  @override
  State<PilihanTerlarisSection> createState() => _PilihanTerlarisSectionState();
}

class _PilihanTerlarisSectionState extends State<PilihanTerlarisSection> {
  late List<FoodItemModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List<FoodItemModel>.from(
      widget.items ?? FoodSectionLogic.defaultItems,
    );
  }

  @override
  void didUpdateWidget(covariant PilihanTerlarisSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != null && widget.items != oldWidget.items) {
      _items = List<FoodItemModel>.from(widget.items!);
    }
  }

  void _toggleFavorite(int index) {
    setState(() {
      final current = _items[index];
      _items[index] = current.copyWith(isFavorite: !current.isFavorite);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: ikon dining cutlery + "FlexFood" + "Pilihan Terlaris" presisi Figma node [1:8063]
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAssets.icDining,
                    width: 12,
                    height: 12,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF17152B),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.restaurant_rounded,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'FlexFood',
                    style: GoogleFonts.roboto(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                      height: 1.17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1.5),
              Text(
                'Pilihan Terlaris',
                style: GoogleFonts.roboto(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF17152B),
                  height: 1.17,
                ),
              ),
            ],
          ),
        ),

        // List horizontal kartu makanan dengan ruang shadow dan jarak presisi 14px Figma
        SizedBox(
          height: 186,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, index) {
              final food = _items[index];
              return FoodCardItem(
                item: food,
                onFavoriteTap: () => _toggleFavorite(index),
                onTap: () => widget.onFoodTap?.call(food),
              );
            },
          ),
        ),
      ],
    );
  }
}
