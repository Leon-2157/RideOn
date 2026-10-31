import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/emulator_nav_bar/virtual_navigation_bar_wrapper.dart';
import 'features/main/presentation/pages/main_screen.dart';
import 'features/splash/presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase not supported on this platform or failed to initialize: $e');
  }
  runApp(const RideOnApp());
}

class RideOnApp extends StatelessWidget {
  const RideOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: emulatorNavigatorKey,
      title: 'RideOn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      builder: (context, child) {
        return VirtualNavigationBarWrapper(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Builder(
        builder: (context) {
          return SplashScreen(
            onAnimationComplete: () {
              // Sesuai Prototype Figma (RideOn Test):
              // Navigasi langsung ke Beranda (MainScreen).
              // Transisi Slide In Left sesuai spesifikasi Figma (node 9:329 -> 9:336).
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const MainScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    final slideTween = Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeInOutCubic));
                    return SlideTransition(
                      position: animation.drive(slideTween),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 650),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
