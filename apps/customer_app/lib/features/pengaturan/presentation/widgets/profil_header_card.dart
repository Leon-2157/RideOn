import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/user_avatar.dart';

/// Card 1: Informasi Akun (Avatar, Nama, No HP, Badge "Verified")
class ProfilHeaderCard extends StatelessWidget {
  final String userName;
  final String phoneNumber;
  final String? photoUrl;
  final bool isVerified;

  const ProfilHeaderCard({
    super.key,
    required this.userName,
    required this.phoneNumber,
    this.photoUrl,
    this.isVerified = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFC7BCFE),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B48FC).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular User Avatar with white ring border
          UserAvatar(
            photoUrl: photoUrl,
            name: userName,
            size: 48,
            borderWidth: 2,
            borderColor: Colors.white,
          ),
          const SizedBox(width: 14),

          // User Info (Name + Phone)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF17152B),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 13,
                      color: Color(0xFF17152B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      phoneNumber,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF17152B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Verified Pill Badge (Cyan/Teal)
          if (isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF8CE1D7),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Verified',
                style: GoogleFonts.roboto(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF114B44),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

