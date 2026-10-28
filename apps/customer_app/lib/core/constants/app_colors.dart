import 'package:flutter/material.dart';

/// AppColors contains the official design tokens from the RideOn Figma project.
/// Reference: figma/ColorPalette
class AppColors {
  AppColors._();

  /// Primary Brand Purple: #6B48FC
  static const Color primary = Color(0xFF6B48FC);

  /// Secondary Accent / Pastel Lavender: #C6BCFF
  static const Color secondary = Color(0xFFC6BCFF);

  /// Dark Neutral / Night Navy (Background & Text): #17152B
  static const Color dark = Color(0xFF17152B);

  /// Pure White: #FFFFFF
  static const Color white = Color(0xFFFFFFFF);

  /// Border / Divider / Inactive Gray: #D6D6D6
  static const Color divider = Color(0xFFD6D6D6);

  /// Gray / Muted Text: #7A798A
  static const Color textMuted = Color(0xFF7A798A);

  /// Light Surface Gray: #F7F7FA
  static const Color surfaceLight = Color(0xFFF7F7FA);

  /// Dark Surface Card: #23203D
  static const Color surfaceDark = Color(0xFF23203D);

  /// Success Green
  static const Color success = Color(0xFF00C853);

  /// Error Red
  static const Color error = Color(0xFFFF3B30);

  /// Splash Screen Linear Gradient (from Figma Ellipse 16)
  /// Top-Right to Bottom-Left
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment(0.58, -0.82), // approx (0.79, 0.09) in Figma UV coords
    end: Alignment(-0.58, 0.81),   // approx (0.21, 0.91) in Figma UV coords
    stops: [0.0, 0.66, 1.0],
    colors: [
      Color(0xFF6B48FC), // #6B48FC
      Color(0xFFC6BCFF), // #C6BCFF
      Color(0xFFFFFFFF), // #FFFFFF
    ],
  );

  /// Soft Purple Radial Glow
  static const RadialGradient purpleGlow = RadialGradient(
    colors: [
      Color(0x806B48FC),
      Color(0x006B48FC),
    ],
    radius: 0.8,
  );
}
