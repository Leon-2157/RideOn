import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityCardWidget extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onTap;

  const ActivityCardWidget({
    super.key,
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC6BCFF),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Lavender circle (56px) + Title & Subtitle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC6BCFF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          activity['icon'] as IconData,
                          color: const Color(0xFF17152B),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            activity['items'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 11.5,
                              color: const Color(0xFF6B6680),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row 2: Date on left + Fresh Green Price on right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity['date'] as String,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                    Text(
                      activity['price'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

