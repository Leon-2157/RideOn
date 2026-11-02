import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;

  const MessageBubble({
    super.key,
    required this.msg,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = msg['sender'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6B48FC) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: AppColors.divider.withValues(alpha: 0.8),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'] as String,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: isUser ? Colors.white : const Color(0xFF17152B),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg['time'] as String,
              style: GoogleFonts.roboto(
                fontSize: 9.5,
                color: isUser
                    ? Colors.white.withValues(alpha: 0.75)
                    : const Color(0xFF6B48FC).withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
