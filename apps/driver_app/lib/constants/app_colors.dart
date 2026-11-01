import 'package:flutter/material.dart';

/// RideOn App Color Palette from Figma
class AppColors {
  AppColors._();

  /// Primary Brand Purple: #6B48FC
  static const Color primary = Color(0xFF6B48FC);

  /// Secondary Accent Purple / Pastel: #C6BCFF
  static const Color secondary = Color(0xFFC6BCFF);

  /// Dark Neutral / Text / Surface: #17152B
  static const Color dark = Color(0xFF17152B);

  /// White / Background: #FFFFFF
  static const Color white = Color(0xFFFFFFFF);

  /// Background / Surface default
  static const Color background = Color(0xFFFFFFFF);

  /// Harmonized Emerald / Mint Green for Online status & positive indicators
  /// Balanced cool tone (hue ~163°) that complements brand purple without chromatic clash
  static const Color onlineGreen = Color(0xFF00C48C);

  /// Deep Emerald Green for high-contrast, legible text on purple & light surfaces
  static const Color onlineGreenDark = Color(0xFF065F46);

  /// RideOn Splash & Brand Linear Gradient
  /// Replicated directly from Figma Ellipse 16 gradient properties
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment(0.58, -0.82),
    end: Alignment(-0.58, 0.81),
    stops: [0.0, 0.663, 1.0],
    colors: [
      primary,
      secondary,
      white,
    ],
  );
}
