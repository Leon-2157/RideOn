import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

/// Input field bergaya glassmorphism dengan indikator validasi (Merah/Hijau/Netral)
class AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool isValid;
  final String? keyName;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isValid = true,
    this.keyName,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    double borderWidth;

    if (controller.text.trim().isEmpty) {
      borderColor = Colors.white.withValues(alpha: 0.35);
      borderWidth = 0.8;
    } else if (isValid) {
      borderColor = const Color(0xFF00B894);
      borderWidth = 1.2;
    } else {
      borderColor = const Color(0xFFE83535);
      borderWidth = 1.2;
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13.0),
        gradient: LinearGradient(
          begin: const Alignment(-0.94, -0.69),
          end: const Alignment(0.94, 0.78),
          stops: const [0.45, 1.0],
          colors: [
            AppColors.primary.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.20),
          ],
        ),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Center(
        child: Row(
          children: [
            Icon(
              prefixIcon,
              size: 16.0,
              color: AppColors.dark,
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: TextField(
                key: keyName != null ? Key(keyName!) : null,
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                onChanged: onChanged,
                style: GoogleFonts.roboto(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.dark,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.roboto(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.dark.withValues(alpha: 0.65),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            ?suffixIcon,
          ],
        ),
      ),
    );
  }
}

