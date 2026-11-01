import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showTop20LeaderboardSheet({
  required BuildContext context,
  required List<Map<String, dynamic>> items,
  required Function(Map<String, dynamic> food) onSelectFood,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: const BoxDecoration(
              color: Color(0xFFF9F7FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
          children: [
            // Drag Handle & Header Top 20
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC6BCFF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B48FC),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B48FC)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFFFFD700),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Top 20 Menu Paling Laris',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            Text(
                              'Peringkat menu terlaris minggu ini',
                              style: GoogleFonts.roboto(
                                fontSize: 11.5,
                                color: const Color(0xFF6B6680),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE2DCFE),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF17152B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE8E2FF)),

            // Tampilan Grid 3-Kolom Kartu Ungu 100% Serasi dengan Ribbon Peringkat Emas/Perak/Perunggu
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                physics: const BouncingScrollPhysics(),
                itemCount: items.length > 20 ? 20 : items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.77,
                ),
                itemBuilder: (context, index) {
                  final food = items[index];
                  final rank = index + 1;

                  // Warna Badge Peringkat
                  Color ribbonColor;
                  Color ribbonTextColor;
                  IconData? rankIcon;

                  if (rank == 1) {
                    ribbonColor = const Color(0xFFFFD700); // Gold
                    ribbonTextColor = const Color(0xFF5B3900);
                    rankIcon = Icons.workspace_premium_rounded;
                  } else if (rank == 2) {
                    ribbonColor = const Color(0xFFE0E3EB); // Silver
                    ribbonTextColor = const Color(0xFF2C3242);
                    rankIcon = Icons.military_tech_rounded;
                  } else if (rank == 3) {
                    ribbonColor = const Color(0xFFE5A97B); // Bronze
                    ribbonTextColor = const Color(0xFF4A2500);
                    rankIcon = Icons.military_tech_rounded;
                  } else {
                    ribbonColor = const Color(0xFF1B1832);
                    ribbonTextColor = Colors.white;
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelectFood(food);
                    },
                    child: Container(
                      width: 133,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7254F0),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF17152B)
                                .withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kotak Gambar Makanan dengan Pita/Badge Peringkat di Pojok Kiri Atas
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              6.0,
                              6.0,
                              6.0,
                              0.0,
                            ),
                            child: AspectRatio(
                              aspectRatio: 121 / 105,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.50),
                                    width: 0.5,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [
                                      Colors.white,
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 1.0],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // Bayangan oval realistis di bawah makanan
                                    Positioned(
                                      bottom: 8,
                                      left: 20,
                                      right: 20,
                                      height: 10,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(
                                            Radius.elliptical(40, 6),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.20,
                                              ),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                          vertical: 2.0,
                                        ),
                                        child: Image.asset(
                                          food['image'] as String,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),

                                    // Badge Ranking Emas / Perak / Perunggu di Pojok Kiri Atas
                                    Positioned(
                                      top: 5,
                                      left: 5,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ribbonColor,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.25,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1.5),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (rankIcon != null) ...[
                                              Icon(
                                                rankIcon,
                                                size: 10,
                                                color: ribbonTextColor,
                                              ),
                                              const SizedBox(width: 1.5),
                                            ],
                                            Text(
                                              '#$rank',
                                              style: GoogleFonts.poppins(
                                                fontSize: 9.0,
                                                fontWeight: FontWeight.w800,
                                                color: ribbonTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Ikon Favorit di Pojok Kanan Atas
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          setSheetState(() {
                                            food['fav'] =
                                                !(food['fav'] as bool? ?? false);
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(
                                            (food['fav'] as bool? ?? false)
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            size: 15,
                                            color: const Color(0xFF17152B),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Detail Teks (Nama, Ikon Toko, Rating, Harga Kuning)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              7.0,
                              3.0,
                              8.0,
                              6.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  food['title'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 1.5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.storefront_rounded,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        food['resto'] as String? ??
                                            'Restoran Mitra',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.roboto(
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white.withValues(
                                            alpha: 0.90,
                                          ),
                                          height: 1.15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2.5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 12.5,
                                          color: Color(0xFFFFD700),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          food['rating'] as String? ?? '4.9',
                                          style: GoogleFonts.roboto(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      food['price'] as String,
                                      style: GoogleFonts.roboto(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFFFD700),
                                        height: 1.10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
          );
        },
      );
    },
  );
}
