import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';

/// Delivery route and address card in Activity Summary
class ActivityDeliveryDetails extends StatelessWidget {
  final String restaurantAddress;
  final String destinationAddress;

  const ActivityDeliveryDetails({
    super.key,
    this.restaurantAddress = 'Nasi Goreng Mas Fuad, Kreung Geukueh',
    this.destinationAddress = 'Kos Dokter Gufran, Kreung Geukueh',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail pengantaran',
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                const Icon(
                  Icons.restaurant_rounded,
                  size: 18,
                  color: Color(0xFFEB5757),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: SizedBox(
                    height: 28,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        4,
                        (_) => Container(
                          width: 2,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF94A3B8),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Icon(
                  Icons.radio_button_checked_rounded,
                  size: 18,
                  color: Color(0xFFEB5757),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alamat restoran',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    restaurantAddress,
                    style: GoogleFonts.roboto(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Alamat pengiriman • 1 km',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    destinationAddress,
                    style: GoogleFonts.roboto(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
