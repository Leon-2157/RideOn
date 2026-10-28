import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/splash_screen_navbar.dart';

void main() {
  runApp(const RideOnDriverApp());
}

class RideOnDriverApp extends StatelessWidget {
  const RideOnDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideOn Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.white,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreenNavbar(),
    );
  }
}
