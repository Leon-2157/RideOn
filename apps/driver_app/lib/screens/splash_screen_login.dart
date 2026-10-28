import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// [SplashScreenLogin]
/// Implementasi SplashScreen flow menuju Halaman Login (Figma Node: 28:2085 -> 28:2089)
///
/// Transisi:
/// - State 1: Layar putih dengan logo RideOn ungu.
/// - State 2: Transisi halus (800ms, easeOut) ke background gradien ungu (#6B48FC -> #C6BCFF)
///   dengan logo RideOn putih.
class SplashScreenLogin extends StatefulWidget {
  final VoidCallback? onCompleted;
  final Duration initialDelay;
  final Duration transitionDuration;
  final Duration endDuration;

  const SplashScreenLogin({
    super.key,
    this.onCompleted,
    this.initialDelay = const Duration(milliseconds: 600),
    this.transitionDuration = const Duration(milliseconds: 800),
    this.endDuration = const Duration(milliseconds: 1250),
  });

  @override
  State<SplashScreenLogin> createState() => _SplashScreenLoginState();
}

class _SplashScreenLoginState extends State<SplashScreenLogin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Timer? _initialTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // Jalankan alur animasi splash sesuai spek Figma
    _initialTimer = Timer(widget.initialDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completeTimer = Timer(widget.endDuration, () {
          if (mounted && widget.onCompleted != null) {
            widget.onCompleted!();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _initialTimer?.cancel();
    _completeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Splash Screen Awal (Putih)
            Image.asset(
              'assets/images/splash_login_white.png',
              fit: BoxFit.cover,
            ),

            // Layer 2: Splash Screen Akhir (Gradien Ungu) - Fade In
            FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                'assets/images/splash_login_purple.png',
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
