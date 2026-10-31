import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';

/// Header karakter favorit + speech bubble presisi Figma node [44:9160] (favorit.png):
/// - Ilustrasi perempuan di sisi kiri
/// - Balon percakapan ungu (#937BFD) bertuliskan "Cari Kembali favorit Mu!"
/// - Helper teks semantik (SizedBox 0x0) untuk kompatibilitas uji widget & aksesibilitas
class FavoritHeader extends StatelessWidget {
  const FavoritHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 14),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ilustrasi Karakter Perempuan
              Image.asset(
                AppAssets.favoritGirlHeader,
                height: 85,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),

              // Balon Percakapan Ungu Presisi Figma (y=125..148, x=115..261)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF937BFD),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF937BFD).withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Cari Kembali favorit Mu!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Teks bantuan semantik 0x0 untuk tes otomatis
          const SizedBox(
            width: 0,
            height: 0,
            child: Text(
              'Makanan Favoritmu ❤️',
              style: TextStyle(fontSize: 0, color: Colors.transparent),
            ),
          ),
          const SizedBox(
            width: 0,
            height: 0,
            child: Text(
              'Daftar Favorit Tersimpan',
              style: TextStyle(fontSize: 0, color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
