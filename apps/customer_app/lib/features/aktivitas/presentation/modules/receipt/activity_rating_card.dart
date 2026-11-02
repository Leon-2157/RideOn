import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'package:rideon/core/constants/app_colors.dart';

/// Rating card for food/service and driver in Activity Summary (Read-Only / Fixed)
class ActivityRatingCard extends StatelessWidget {
  final int foodRating;
  final int driverRating;
  final ValueChanged<int>? onFoodRatingChanged;
  final ValueChanged<int>? onDriverRatingChanged;
  final String driverName;
  final String vehicleInfo;
  final String serviceType;
  final bool isReadOnly;

  const ActivityRatingCard({
    super.key,
    required this.foodRating,
    required this.driverRating,
    this.onFoodRatingChanged,
    this.onDriverRatingChanged,
    required this.driverName,
    required this.vehicleInfo,
    this.serviceType = 'FlexFood',
    this.isReadOnly = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFoodService = serviceType.toLowerCase().contains('food');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bagian Rating Makanan hanya muncul jika service adalah FlexFood
          if (isFoodService) ...[
            Text(
              'Rating Makanan Diberikan',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF17152B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final filled = index < foodRating;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 28,
                    color: filled
                        ? const Color(0xFFFFCC00)
                        : const Color(0xFFD1D5DB),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 14),
          ],

          // Rating Driver (FlexRide, FlexFood, FlexSend)
          Text(
            'Rating Driver Diberikan',
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF17152B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final filled = index < driverRating;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 28,
                  color: filled
                      ? const Color(0xFFFFCC00)
                      : const Color(0xFFD1D5DB),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  image: const DecorationImage(
                    image: AssetImage(AppAssets.driverGufran),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverName,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  Text(
                    vehicleInfo,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
