import 'package:flutter/material.dart';
import 'package:rideon/core/constants/app_assets.dart';

/// Center cross-fading logo widget in Splash Screen
class SplashLogoView extends StatelessWidget {
  final double scale;
  final double fadeInOpacity;
  final double whiteLogoOpacity;

  const SplashLogoView({
    super.key,
    required this.scale,
    required this.fadeInOpacity,
    required this.whiteLogoOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: fadeInOpacity,
          child: SizedBox(
            width: 250,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Primary Purple Logo
                Opacity(
                  opacity: (1.0 - whiteLogoOpacity).clamp(0.0, 1.0),
                  child: Image.asset(
                    AppAssets.logoPrimary,
                    width: 250,
                    fit: BoxFit.contain,
                  ),
                ),

                // White Logo
                Opacity(
                  opacity: whiteLogoOpacity.clamp(0.0, 1.0),
                  child: Image.asset(
                    AppAssets.logoWhite,
                    width: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
