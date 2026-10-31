import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickRepliesBar extends StatelessWidget {
  final List<String> quickReplies;
  final Function(String reply) onSelectReply;

  const QuickRepliesBar({
    super.key,
    required this.quickReplies,
    required this.onSelectReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: quickReplies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = quickReplies[index];
          return ActionChip(
            label: Text(
              reply,
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: const Color(0xFF6B48FC),
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFFEDE8FF),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: () => onSelectReply(reply),
          );
        },
      ),
    );
  }
}
