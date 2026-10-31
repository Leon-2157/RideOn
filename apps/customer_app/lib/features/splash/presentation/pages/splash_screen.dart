import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';

/// SplashScreen strictly implementing the Figma design:
/// - Screen 1 (Figma 182:2736): White canvas (#FFFFFF)
/// - Screen 2 (Figma 182:2700): Scaled logo & expanding gradient circle
/// - Screen 3 (Figma 182:2757): Full gradient fill & white logo
class SplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;

  const SplashScreen({
    super.key,
    this.onAnimationComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Phase 1: Logo scale & fade in (0.0 -> 0.4)
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoFadeInAnimation;

  // Phase 2: Expanding gradient ellipse (0.3 -> 0.8)
  late final Animation<double> _circleExpansionAnimation;

  // Phase 3: Logo cross-fade to white (0.45 -> 0.8)
  late final Animation<double> _whiteLogoOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _logoFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _circleExpansionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.80, curve: Curves.easeInOutCubic),
      ),
    );

    _whiteLogoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.78, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.onAnimationComplete != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              widget.onAnimationComplete!();
            }
          });
        }
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isGradientActive = _whiteLogoOpacityAnimation.value > 0.5;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isGradientActive
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: AppColors.white,
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (widget.onAnimationComplete != null) {
                  widget.onAnimationComplete!();
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Base white background (Figma Screen 182:2736)
                  const Positioned.fill(
                    child: ColoredBox(color: AppColors.white),
                  ),

                  // Expanding Gradient Ellipse (Figma Screen 182:2700 -> 182:2757)
                  Builder(
                    builder: (context) {
                      final progress = _circleExpansionAnimation.value;
                      if (progress <= 0.0) return const SizedBox.shrink();

                      final currentRadius = progress * maxRadius * 1.15;

                      return Center(
                        child: ClipOval(
                          child: Container(
                            width: currentRadius * 2,
                            height: currentRadius * 2,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.splashGradient,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Center Logo (Smooth cross-fade between primary and white logos)
                  Center(
                    child: Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: Opacity(
                        opacity: _logoFadeInAnimation.value,
                        child: SizedBox(
                          width: 250,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Primary Purple Logo
                              Opacity(
                                opacity: (1.0 - _whiteLogoOpacityAnimation.value)
                                    .clamp(0.0, 1.0),
                                child: Image.asset(
                                  AppAssets.logoPrimary,
                                  width: 250,
                                  fit: BoxFit.contain,
                                ),
                              ),

                              // White Logo
                              Opacity(
                                opacity: _whiteLogoOpacityAnimation.value
                                    .clamp(0.0, 1.0),
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
