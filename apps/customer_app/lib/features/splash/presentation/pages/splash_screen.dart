import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../modules/splash_logo/expanding_circle_painter.dart';
import '../modules/splash_logo/splash_logo_view.dart';

export '../modules/splash_logo/expanding_circle_painter.dart';
export '../modules/splash_logo/splash_logo_view.dart';

/// SplashScreen strictly implementing the Figma prototype (RideOn Test):
/// - Phase 1: White background with scaled center logo (Figma node 9:325)
/// - Phase 2: Expanding gradient circle until 100% screen is covered (Figma node 9:329)
/// - Phase 3: Transition to Beranda / MainScreen (Figma node 9:336)
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

  // Phase 1: Logo scale & fade in (0.0 -> 0.40)
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoFadeInAnimation;

  // Phase 2: Expanding gradient ellipse (0.30 -> 0.85)
  late final Animation<double> _circleExpansionAnimation;

  // Phase 3: Logo cross-fade to white (0.35 -> 0.75)
  late final Animation<double> _whiteLogoOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Scale animation with gentle bounce
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.65, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 50.0,
      ),
    ]).animate(_controller);

    // Initial fade-in of the logo
    _logoFadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.30, curve: Curves.easeIn),
      ),
    );

    // Expanding circle: expands rapidly across the entire screen
    _circleExpansionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.82, curve: Curves.easeInOutCubic),
      ),
    );

    // Logo color transition to pure white
    _whiteLogoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 0.72, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.onAnimationComplete != null) {
          Future.delayed(const Duration(milliseconds: 200), () {
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
    final diagonalHalf =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final maxRadius = diagonalHalf * 1.4;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isGradientActive = _circleExpansionAnimation.value > 0.7;
        final isFullyCovered = _circleExpansionAnimation.value >= 0.98;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isGradientActive
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: isFullyCovered ? null : AppColors.white,
            body: Container(
              decoration: isFullyCovered
                  ? const BoxDecoration(gradient: AppColors.splashGradient)
                  : null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (widget.onAnimationComplete != null) {
                    widget.onAnimationComplete!();
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Base white background
                    if (!isFullyCovered)
                      const Positioned.fill(
                        child: ColoredBox(color: AppColors.white),
                      ),

                    // Expanding Gradient Ellipse via CustomPainter
                    if (!isFullyCovered && _circleExpansionAnimation.value > 0.0)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: ExpandingCirclePainter(
                            radius: _circleExpansionAnimation.value * maxRadius,
                            gradient: AppColors.splashGradient,
                          ),
                        ),
                      ),

                    // Center Logo (Smooth cross-fade between primary and white logos)
                    SplashLogoView(
                      scale: _logoScaleAnimation.value,
                      fadeInOpacity: _logoFadeInAnimation.value,
                      whiteLogoOpacity: _whiteLogoOpacityAnimation.value,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
