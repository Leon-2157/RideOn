import 'package:flutter/material.dart';
import 'screens/auth/toko_login_screen.dart';
import 'screens/main_toko_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const TokoApp());
}

class TokoApp extends StatefulWidget {
  final bool initialLoggedIn;
  const TokoApp({super.key, this.initialLoggedIn = false});

  @override
  State<TokoApp> createState() => _TokoAppState();
}

class _TokoAppState extends State<TokoApp> {
  late bool _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.initialLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    // ponytail: single root widget handles authentication switch; upgrade to go_router if deep links needed
    return MaterialApp(
      title: 'Mitra Toko',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
        physics: const ClampingScrollPhysics(),
      ),
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
