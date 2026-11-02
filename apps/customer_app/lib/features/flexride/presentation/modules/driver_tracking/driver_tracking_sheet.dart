import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'package:rideon/core/constants/app_colors.dart';

class DriverTrackingSheet extends StatefulWidget {
  final bool isArrived;
  final bool isTripStarted;
  final VoidCallback onChatWithDriver;
  final VoidCallback onCallWithDriver;
  final VoidCallback onMetDriver;
  final VoidCallback? onCompleteOrder;

  const DriverTrackingSheet({
    super.key,
    required this.isArrived,
    this.isTripStarted = false,
    required this.onChatWithDriver,
    required this.onCallWithDriver,
    required this.onMetDriver,
    this.onCompleteOrder,
  });

  @override
  State<DriverTrackingSheet> createState() => _DriverTrackingSheetState();
}

class _DriverTrackingSheetState extends State<DriverTrackingSheet> {
  // Flag apakah perjalanan sudah sampai di tujuan akhir
  bool _isDestinationArrived = false;

  @override
  void initState() {
    super.initState();
    _startCooldownIfNeeded();
  }

  @override
  void didUpdateWidget(DriverTrackingSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isTripStarted && widget.isTripStarted) {
      _startCooldownIfNeeded();
    }
  }

  void _startCooldownIfNeeded() {
    if (widget.isTripStarted) {
      _isDestinationArrived = false;
      // Simulasi perjalanan: setelah 4.5 detik, status berubah menjadi 'Customer Sudah Sampai di Tujuan'
      Future.delayed(const Duration(milliseconds: 4500), () {
        if (mounted) {
          setState(() {
            _isDestinationArrived = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: const Color(0xFFC6BCFF).withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                color: (widget.isArrived || (widget.isTripStarted && _isDestinationArrived))
                    ? const Color(0xFFD4EDDA)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (widget.isArrived || (widget.isTripStarted && _isDestinationArrived))
                      ? const Color(0xFF27AE60)
                      : const Color(0xFF6B48FC),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  if (widget.isArrived) ...[
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
                  ] else if (widget.isTripStarted) ...[
                    if (_isDestinationArrived) ...[
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF27AE60), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer Sudah Sampai di Tujuan!',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF27AE60),
                              ),
                            ),
                            Text(
                              'Perjalanan selesai, terima kasih telah berkendara!',
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
                          'Dalam perjalanan untuk sampai ke tujuan',
                          style: GoogleFonts.roboto(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6B48FC),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17152B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Tiba Dalam 10 Menit',
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
                    onTap: widget.onChatWithDriver,
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
                    onTap: widget.onCallWithDriver,
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
            if (widget.isArrived)
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: widget.onMetDriver,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17152B),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Saya sudah Bertemu Driver',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom Action Button: 'Selesaikan Orderan' (HANYA MUNCUL & BISA DITEKAN SETELAH CUSTOMER SUDAH SAMPAI DI TUJUAN)
            if (widget.isTripStarted && _isDestinationArrived)
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: widget.onCompleteOrder,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17152B),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Selesaikan Orderan',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  }
}
