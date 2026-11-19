import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'data/toko_state.dart';
import 'screens/auth/toko_login_screen.dart';
import 'screens/main_toko_screen.dart';
import 'services/toko_api_service.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  bool restoredLogin = false;
  try {
    final api = TokoApiService();
    if (await api.restoreSession()) {
      final user = await api.getMe();
      TokoState.hydrateFromUser(user);
      restoredLogin = true;
    }
  } catch (_) {}

  runApp(TokoApp(initialLoggedIn: restoredLogin));
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
              onLogout: () async {
                await TokoApiService().logout();
                if (mounted) {
                  setState(() => _isLoggedIn = false);
                }
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
