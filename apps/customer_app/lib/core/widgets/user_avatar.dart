import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable User Avatar Component for RideOn
/// Strictly adheres to Figma circular styling with white border.
/// - If a photo exists (Base64 data URI, HTTP URL, or local file), it displays the photo.
/// - If no photo exists (e.g. new user), it displays a clean brand-colored
///   avatar with the user's initials (e.g., "MT" for Muhammad Taufiq) or
///   a person silhouette icon. Never uses placeholder mock avatars.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final File? localImageFile;
  final String? name;
  final double size;
  final double borderWidth;
  final Color borderColor;
  final List<BoxShadow>? boxShadow;

  const UserAvatar({
    super.key,
    this.photoUrl,
    this.localImageFile,
    this.name,
    this.size = 48.0,
    this.borderWidth = 2.0,
    this.borderColor = Colors.white,
    this.boxShadow,
  });

  String _getInitials(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return '$first$second'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }

  Widget _buildPlaceholder() {
    final initials = _getInitials(name);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF8B6BFF), Color(0xFF6B48FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: GoogleFonts.poppins(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              )
            : Icon(
                Icons.person_rounded,
                size: size * 0.55,
                color: Colors.white,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageContent;

    if (localImageFile != null && localImageFile!.existsSync()) {
      imageContent = Image.file(
        localImageFile!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      final trimmed = photoUrl!.trim();
      if (trimmed.startsWith('data:image') ||
          (trimmed.length > 200 && !trimmed.startsWith('http') && !trimmed.startsWith('/'))) {
        try {
          final cleanBase64 = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
          final bytes = base64Decode(cleanBase64);
          imageContent = Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );
        } catch (_) {
          imageContent = _buildPlaceholder();
        }
      } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        imageContent = Image.network(
          trimmed,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } else if (trimmed.startsWith('/') || trimmed.contains('user_profile_')) {
        final file = File(trimmed);
        if (file.existsSync()) {
          imageContent = Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          );
        } else {
          imageContent = _buildPlaceholder();
        }
      } else if (trimmed.startsWith('assets/')) {
        imageContent = Image.asset(
          trimmed,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } else {
        imageContent = _buildPlaceholder();
      }
    } else {
      imageContent = _buildPlaceholder();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: boxShadow,
      ),
      child: ClipOval(
        child: imageContent,
      ),
    );
  }
}
