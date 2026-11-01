import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityCardWidget extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;

  const ActivityCardWidget({
    super.key,
    required this.activity,
    required this.onTap,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFC6BCFF),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 14.0, 18.0, 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Lavender circle (58px) with border + Title & Subtitle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC6BCFF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF5B36F5),
                          width: 2.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          activity['icon'] as IconData,
                          color: const Color(0xFF1E143E),
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activity['semanticTitle'] != null)
                            SizedBox(
                              width: 0,
                              height: 0,
                              child: Text(
                                activity['semanticTitle'] as String,
                                style: const TextStyle(
                                  fontSize: 0,
                                  color: Colors.transparent,
                                ),
                              ),
                            ),
                          Text(
                            activity['title'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                              height: 1.3,
                            ),
                          ),
                          if ((activity['items'] as String?)?.isNotEmpty == true) ...[
                            const SizedBox(height: 3),
                            Text(
                              activity['items'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1A1A1A),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row 2: Date on left + Favorite Button & Green Price on right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity['date'] as String,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onToggleFavorite != null) ...[
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onToggleFavorite,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Icon(
                                activity['isFav'] == true
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: activity['isFav'] == true
                                    ? const Color(0xFF6B48FC)
                                    : const Color(0xFFA6A3B3),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

