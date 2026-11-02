import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import '../header/flexsend_header.dart';
import '../models/flexsend_item_model.dart';
import 'driver_card_widget.dart';

class DeliveringProgressView extends StatefulWidget {
  final List<FlexSendLocation> locations;
  final VoidCallback onBack;
  final VoidCallback onAdvanceToArrived;

  const DeliveringProgressView({
    super.key,
    this.locations = const [],
    required this.onBack,
    required this.onAdvanceToArrived,
  });

  @override
  State<DeliveringProgressView> createState() => _DeliveringProgressViewState();
}

class _DeliveringProgressViewState extends State<DeliveringProgressView> {
  Timer? _arrivedTimer;

  @override
  void initState() {
    super.initState();
    // Otomatis sampai ke rumah setelah 4.5 detik perjalanan
    _arrivedTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) {
        widget.onAdvanceToArrived();
      }
    });
  }

  @override
  void dispose() {
    _arrivedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.locations.fold<int>(
      0,
      (sum, loc) => sum + loc.items.length,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),
      body: Stack(
        children: [
          // Background Peta
          Positioned.fill(
            child: Image.asset(
              AppAssets.mapFlexSend,
              fit: BoxFit.cover,
            ),
          ),

          // Header FlexSend Konsisten di bagian atas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FlexSendHeader(
              title: 'FlexSend',
              onBack: widget.onBack,
            ),
          ),

          // Bottom Delivering Card Semi-Transparan Konsisten FlexRide (Color 0xFFC6BCFF 85% opacity)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFC6BCFF).withValues(alpha: 0.85),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle Bar
                      Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF828282),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Status Banner (Green: Menuju rumah anda)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4F7DF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.motorcycle_rounded,
                                size: 22,
                                color: Color(0xFF1E7E34),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Driver Menuju Rumah Anda!',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1E7E34),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Belanjaan lengkap ($totalItems item) • Siapkan uang tunai',
                                    style: GoogleFonts.roboto(
                                      fontSize: 11,
                                      color: const Color(0xFF4A4458),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2EFFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '~5 mnt',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B48FC),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Driver Profile Card
                      const DriverCardWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
