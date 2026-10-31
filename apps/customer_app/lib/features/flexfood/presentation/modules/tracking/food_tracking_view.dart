import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'package:rideon/features/chat/presentation/modules/call/voice_call_overlay.dart';
import 'package:rideon/features/chat/presentation/pages/chat_screen.dart';
import '../header/flexfood_header.dart';

class FoodTrackingView extends StatelessWidget {
  final VoidCallback onBack;
  final int trackingStep;
  final VoidCallback onAdvanceStep;
  final VoidCallback onFinish;

  const FoodTrackingView({
    super.key,
    required this.onBack,
    required this.trackingStep,
    required this.onAdvanceStep,
    required this.onFinish,
  });

  static const List<String> titles = [
    'Driver Menuju Restoran...',
    'Driver Menunggu Pesanan...',
    'Driver Sedang Mengantar...',
    'Pesanan Telah Sampai...',
  ];

  static const List<String> descriptions = [
    'Driver (Muhammad Luthfi Fadil) sedang dalam perjalanan ke Dapur Banku City. Estimasi tiba < 5 menit.',
    'Driver telah tiba di restoran. Menunggu makanan selesai dimasak oleh Dapur Banku City.',
    'Driver sedang dalam perjalanan menuju Rumah Anda (Jl. Brawl No. 77). Estimasi tiba 8 menit.',
    'Pesanan #8821 telah tiba di Rumah (Jl. Brawl No.77). Silakan ambil pesanan Anda.',
  ];

  static const List<double> progressValues = [0.35, 0.65, 0.85, 1.0];

  @override
  Widget build(BuildContext context) {
    final isFinished = trackingStep == 3;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          FlexFoodHeader(
            title: '',
            onBack: onBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tracking Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7BCFE),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B48FC)
                              .withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // State Icon
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEDE8FF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFinished
                                ? Icons.storefront_rounded
                                : Icons.delivery_dining_rounded,
                            size: 32,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title
                        Text(
                          titles[trackingStep],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Description
                        Text(
                          descriptions[trackingStep],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 11.5,
                            color: const Color(0xFF17152B),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressValues[trackingStep],
                            backgroundColor: const Color(0xFFE2DCFE),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF6B48FC)),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Order snippet container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Dapur Banku City 2 Item',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total Rp 38.000 Lunas via E-Wallet',
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF28A745),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Driver Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color:
                              const Color(0xFF6B48FC).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        // Driver Photo
                        Stack(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF6B48FC), width: 2),
                                image: const DecorationImage(
                                  image: AssetImage(AppAssets.driverLuthfi),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 12, color: Color(0xFFFFB300)),
                                  Text(
                                    '4.9',
                                    style: GoogleFonts.roboto(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF17152B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Driver details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Muhammad Luthfi Fadil',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B1832),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'BK 789 M',
                                      style: GoogleFonts.roboto(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Honda Vario 160 Hitam',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.roboto(
                                        fontSize: 10,
                                        color: const Color(0xFF6B6680),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Chat button
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              color: Color(0xFF6B48FC)),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => const ChatScreen()),
                            );
                          },
                        ),

                        // Call button
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4F7DF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.phone_rounded,
                                color: Color(0xFF28A745), size: 16),
                          ),
                          onPressed: () {
                            showGeneralDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel: 'VoiceCall',
                              barrierColor:
                                  Colors.black.withValues(alpha: 0.35),
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                              pageBuilder: (dialogContext, anim1, anim2) {
                                return const VoiceCallOverlay();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Simulation step switcher
                  if (!isFinished)
                    Center(
                      child: TextButton.icon(
                        onPressed: onAdvanceStep,
                        icon:
                            const Icon(Icons.fast_forward_rounded, size: 16),
                        label: Text(
                          'Simulasi Langkah (${trackingStep + 1}/4)',
                          style: GoogleFonts.roboto(fontSize: 11),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Action Button
                  if (isFinished)
                    OutlinedButton(
                      onPressed: onFinish,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFF28A745), width: 1.5),
                        foregroundColor: const Color(0xFF28A745),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'SELESAI',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ChatScreen(
                              showBackButton: true,
                              initialShowDetail: true,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE83535)),
                        foregroundColor: const Color(0xFFE83535),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'HUBUNGI DRIVER',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
