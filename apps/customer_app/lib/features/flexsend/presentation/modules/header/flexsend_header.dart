import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlexSendHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const FlexSendHeader({
    super.key,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              GestureDetector(
                key: const Key('btn_flexsend_header_back'),
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
}

class FlexSendCircularBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const FlexSendCircularBackButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('btn_flexsend_back_circle'),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back_rounded,
            size: 20, color: Color(0xFF17152B)),
      ),
    );
  }
}
