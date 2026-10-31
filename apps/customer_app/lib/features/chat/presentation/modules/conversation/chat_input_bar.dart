import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.divider.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F6FB),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.7),
                    width: 0.8,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: const Color(0xFF17152B),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan untuk driver...',
                    hintStyle: GoogleFonts.roboto(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF6B48FC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
