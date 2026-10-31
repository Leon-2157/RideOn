import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import '../header/flexsend_header.dart';
import 'driver_card_widget.dart';

class ShoppingProgressView extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onAdvanceToDelivering;

  const ShoppingProgressView({
    super.key,
    required this.onBack,
    required this.onAdvanceToDelivering,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.mapFlexSend,
              fit: BoxFit.cover,
            ),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: FlexSendCircularBackButton(onTap: onBack),
          ),

          // Bottom Shopping Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              decoration: const BoxDecoration(
                color: Color(0xFFC7BCFE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Banner (Yellow: Sedang Membelanjakan Barang)
                  GestureDetector(
                    key: const Key('banner_sedang_belanja'),
                    onTap: onAdvanceToDelivering,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2D1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFB300)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE082),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shopping_cart_rounded,
                                size: 18, color: Color(0xFF8D6E00)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Driver Sedang Membelanjakan Barang',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF8D6E00),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Di Pasar Pagi Batuphat (Lokasi 1 dari 2)',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10.5,
                                    color: const Color(0xFF8D6E00),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: Color(0xFF8D6E00)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Driver Card
                  const DriverCardWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
