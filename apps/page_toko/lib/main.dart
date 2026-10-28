import 'package:flutter/material.dart';
import 'screens/auth/toko_login_screen.dart';
import 'screens/main_toko_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const TokoApp());
}

class TokoApp extends StatefulWidget {
  const TokoApp({super.key});

  @override
  State<TokoApp> createState() => _TokoAppState();
}

class _TokoAppState extends State<TokoApp> {
  // Set to true to start directly in the store dashboard, or false to start at login
  bool _isLoggedIn = true;

  @override
  Widget build(BuildContext context) {
    // ponytail: single root widget handles authentication switch; upgrade to go_router if deep links needed
    return MaterialApp(
      title: 'Mitra Toko',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: _isLoggedIn
          ? MainTokoScreen(
              onLogout: () {
                setState(() => _isLoggedIn = false);
              },
            )
          : TokoLoginScreen(
              onLoginSuccess: () {
                setState(() => _isLoggedIn = true);
              },
            ),
    );
  }
}
