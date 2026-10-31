import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Search bar mandiri di header Beranda, presisi Figma node [1:8089], [1:8090]:
/// - Kapsul putih bersih dengan rounded corners 17.5px
/// - Ikon search kaca pembesar hitam #17152B
/// - Hint text abu-abu lembut
class HomeSearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String hintText;

  const HomeSearchBar({
    super.key,
    this.onTap,
    this.onChanged,
    this.hintText = 'Cari makanan, tujuan, layanan...',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF17152B).withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              size: 20,
              color: Color(0xFF17152B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hintText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF17152B).withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
