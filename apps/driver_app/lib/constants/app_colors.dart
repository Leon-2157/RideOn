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
