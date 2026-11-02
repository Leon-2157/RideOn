import 'package:flutter/material.dart';
import 'promo_item_model.dart';

/// Kartu banner promo individual dengan aspect ratio presisi Figma.
class PromoCardItem extends StatelessWidget {
  final PromoItemModel item;
  final VoidCallback? onTap;

  const PromoCardItem({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 2.3,
          child: Image.asset(
            item.imageAsset,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

