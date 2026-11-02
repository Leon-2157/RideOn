import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';

class VehicleOptionCard extends StatelessWidget {
  final String name;
  final String desc;
  final String price;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const VehicleOptionCard({
    super.key,
    required this.name,
    required this.desc,
    required this.price,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B48FC) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6B48FC)
                    : const Color(0xFF17152B),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.roboto(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  Text(
                    desc,
                    style: GoogleFonts.roboto(
                      fontSize: 10.5,
                      color: isSelected
                          ? const Color(0xFF6B48FC)
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: GoogleFonts.roboto(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B48FC),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
