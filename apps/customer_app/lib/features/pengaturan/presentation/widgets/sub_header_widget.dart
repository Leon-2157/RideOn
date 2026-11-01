import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Header Sub-Screen dengan gradient ungu lembut dan tombol kembali sesuai desain Figma
Widget buildSubHeader(BuildContext context, String title, {VoidCallback? onBack}) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFB4A5FE),
          Color(0xFFE2DCFE),
          Color(0xFFF7F5FF),
        ],
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).pop(),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E0FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: Color(0xFF17152B),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF17152B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 34),
          ],
        ),
      ),
    ),
  );
}

/// Input field ungu serbaguna untuk sub-screens pengaturan
Widget buildInputField({
  required TextEditingController controller,
  required String hintText,
  required IconData icon,
  bool isPassword = false,
  TextInputType keyboardType = TextInputType.text,
}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFDCD7FF),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.6),
        width: 1.2,
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF17152B)),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: const Color(0xFF17152B),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.roboto(
                fontSize: 12,
                color: const Color(0xFF6B6680),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    ),
  );
}
