import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'package:rideon/core/constants/app_colors.dart';

class DriverTrackingSheet extends StatelessWidget {
  final bool isArrived;
  final VoidCallback onChatWithDriver;
  final VoidCallback onCallWithDriver;
  final VoidCallback onMetDriver;

  const DriverTrackingSheet({
    super.key,
    required this.isArrived,
    required this.onChatWithDriver,
    required this.onCallWithDriver,
    required this.onMetDriver,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Color(0xFFD6CEFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF828282),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Status Pill
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isArrived ? const Color(0xFFD4EDDA) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isArrived
                      ? const Color(0xFF27AE60)
                      : const Color(0xFF6B48FC),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  if (isArrived) ...[
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF27AE60), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver Sudah Tiba di Titik Jemput!',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF27AE60),
                            ),
                          ),
                          Text(
                            'Temui Bapak Pikri di depan Mr.DIY',
                            style: GoogleFonts.roboto(
                              fontSize: 10.5,
                              color: const Color(0xFF27AE60),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Text(
                        'Driver Menuju Lokasimu',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B48FC),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17152B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Tiba Dalam 3 Menit',
                        style: GoogleFonts.roboto(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Driver Card
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                      image: const DecorationImage(
                        image: AssetImage(AppAssets.driverPikri),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pikri Haykal',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF17152B),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'BG 4563 R',
                                style: GoogleFonts.roboto(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.star_rounded,
                                size: 14, color: Color(0xFFF1C40F)),
                            Text(
                              '4.9',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Honda Vario 160 Hitam',
                          style: GoogleFonts.roboto(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chat Icon Button
                  GestureDetector(
                    onTap: onChatWithDriver,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE8FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Color(0xFF6B48FC),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Call Icon Button
                  GestureDetector(
                    onTap: onCallWithDriver,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.phone_rounded,
                        color: Color(0xFF27AE60),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pickup location description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF27AE60),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jemput: Jl. Brawl No. 77 (Patokan: Depan Mr.DIY)',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Action Button: 'Saya sudah Bertemu Driver'
            if (isArrived)
              GestureDetector(
                onTap: onMetDriver,
                child: Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF17152B),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Saya sudah Bertemu Driver',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
