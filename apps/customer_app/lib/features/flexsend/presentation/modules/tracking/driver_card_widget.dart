import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';

class DriverCardWidget extends StatelessWidget {
  final VoidCallback? onChat;
  final VoidCallback? onCall;

  const DriverCardWidget({
    super.key,
    this.onChat,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Driver Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(AppAssets.driverPikri),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Driver details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Pikri Haykal',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.star, size: 14, color: Color(0xFFFFB300)),
                    const SizedBox(width: 2),
                    Text(
                      '4.9',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    Expanded(
                      child: Text(
                        'Honda Vario 160 Hitam',
                        style: GoogleFonts.roboto(
                          fontSize: 10.5,
                          color: const Color(0xFF6B6680),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chat & Call Actions
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                color: Color(0xFF6B48FC)),
            onPressed: onChat ?? () {},
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.call_rounded,
                size: 18, color: Color(0xFF28A745)),
          ),
        ],
      ),
    );
  }
}
