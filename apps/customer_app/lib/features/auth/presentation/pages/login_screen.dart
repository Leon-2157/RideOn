import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../main/presentation/pages/main_screen.dart';
import '../../data/auth_service.dart';
import '../modules/login_form/login_form_view.dart';
import '../modules/login_header/login_header_view.dart';
import '../modules/login_social/login_social_view.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Halaman Login strictly matching Figma:
/// - figma/HalamanLogin/Login.png
/// - figma/HalamanLogin/Login kata sandi salah.png
/// - Gradient background (#6B48FC to #C6BCFF to #FFFFFF)
/// - Frosted glass card with border blur and soft shadow
/// - White RideOn Logo in center
/// - Translucent glass input fields (No. WhatsApp / Email & Kata Sandi)
/// - Error banner if credentials wrong (figma: Login kata sandi salah.png)
/// - "Lupa kata sandi?" right-aligned -> navigates to ForgotPasswordScreen
/// - "MASUK" primary dark navy button (#17152B)
/// - "ATAU" divider
/// - "Lanjutkan Dengan Google" white elevated button with Google icon
/// - "Belum punya akun? Daftar Sekarang" footer -> navigates to RegisterScreen
class LoginScreen extends StatefulWidget {
  final String? initialIdentifier;

  const LoginScreen({super.key, this.initialIdentifier});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _identifierController;
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _hasLoginError = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _identifierController =
        TextEditingController(text: widget.initialIdentifier ?? '');
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _hasLoginError = false;
    });

    try {
      final credential = await _authService.signInWithGoogle();
      if (!mounted) return;

      if (credential != null && credential.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Google gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() {
        _hasLoginError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasLoginError = false;
    });

    try {
      // Menggunakan Smart Detector: bisa Email ATAU No. WhatsApp
      await _authService.signInWithIdentifier(
        identifier: identifier,
        password: password,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    } catch (e) {
      debugPrint('[LOGIN ERROR]: $e');
      if (!mounted) return;
      setState(() {
        _hasLoginError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width > 393 ? 373 : size.width - 20,
                ),
                child: _buildGlassCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 24.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: const Color(0xFFF1F1FD).withValues(alpha: 0.60),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                offset: const Offset(0, 4),
                blurRadius: 20.0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // [Module] Logo RideOn (White)
              const LoginHeaderView(),
              const SizedBox(height: 15),

              // [Module] Form email+password + error banner + tombol MASUK
              LoginFormView(
                identifierController: _identifierController,
                passwordController: _passwordController,
                obscurePassword: _obscurePassword,
                hasLoginError: _hasLoginError,
                isLoading: _isLoading,
                onToggleObscure: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                onSubmit: _submitLogin,
                onForgotPassword: _navigateToForgotPassword,
              ),
              const SizedBox(height: 10),

              // [Module] ATAU divider + tombol Google + footer Daftar Sekarang
              LoginSocialView(
                isLoading: _isLoading,
                onGoogleLogin: _handleGoogleLogin,
                onRegisterTap: _navigateToRegister,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
