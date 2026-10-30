import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/main/presentation/pages/main_screen.dart';
import 'features/splash/presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RideOnApp());
}

class RideOnApp extends StatelessWidget {
  const RideOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideOn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: Builder(
        builder: (context) {
          return SplashScreen(
            onAnimationComplete: () {
              // Cek apakah user sudah login sebelumnya (Session Persistence)
              final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
              final Widget targetScreen =
                  isLoggedIn ? const MainScreen() : const LoginScreen();

              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      targetScreen,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
