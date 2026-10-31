import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../main/presentation/pages/main_screen.dart';
import '../../data/auth_service.dart';
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
              // Logo RideOn (White)
              Image.asset(
                AppAssets.logoWhite,
                width: 124,
                height: 83,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 15),

              // Input 1: No. WhatsApp / Email
              _buildInputField(
                controller: _identifierController,
                hintText: 'No. WhatsApp / Email',
                prefixIcon: Icons.person_rounded,
                keyboardType: TextInputType.emailAddress,
                keyName: 'input_login_identifier',
              ),
              const SizedBox(height: 15),

              // Input 2: Kata Sandi
              _buildInputField(
                controller: _passwordController,
                hintText: 'Kata Sandi',
                prefixIcon: Icons.lock_rounded,
                obscureText: _obscurePassword,
                keyName: 'input_login_password',
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 17,
                    color: AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Lupa kata sandi?
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  key: const Key('link_lupa_kata_sandi'),
                  onTap: _navigateToForgotPassword,
                  child: Text(
                    'Lupa kata sandi?',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.dark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Error banner matching Figma Login kata sandi salah.png
              if (_hasLoginError) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE83535), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFE83535), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Email/WhatsApp atau kata sandi yang Anda masukkan salah.',
                          style: GoogleFonts.roboto(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE83535),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Tombol: MASUK
              _buildPrimaryButton(),
              const SizedBox(height: 10),

              // Divider: ATAU
              _buildOrDivider(),
              const SizedBox(height: 10),

              // Tombol: Lanjutkan Dengan Google
              _buildGoogleButton(),
              const SizedBox(height: 24),

              // Footer: Belum punya akun? Daftar Sekarang
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    String? keyName,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13.0),
        gradient: LinearGradient(
          begin: const Alignment(-0.94, -0.69),
          end: const Alignment(0.94, 0.78),
          stops: const [0.45, 1.0],
          colors: [
            AppColors.primary.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.20),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(2, 2),
            blurRadius: 8.0,
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            prefixIcon,
            size: 19,
            color: AppColors.dark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: keyName != null ? Key(keyName) : null,
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.dark,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: hintText,
                hintStyle: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: AppColors.dark.withValues(alpha: 0.70),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          ?suffixIcon,
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      height: 42,
      width: double.infinity,
      child: ElevatedButton(
        key: const Key('btn_masuk_login'),
        onPressed: _submitLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dark,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13.0),
          ),
          padding: EdgeInsets.zero,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'MASUK',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.dark.withValues(alpha: 0.40),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'ATAU',
            style: GoogleFonts.roboto(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: AppColors.dark,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.dark.withValues(alpha: 0.40),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      height: 42,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3303045E),
            offset: Offset(0, 2),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('btn_google_login'),
          borderRadius: BorderRadius.circular(13.0),
          onTap: _isLoading ? null : _handleGoogleLogin,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AppAssets.googleIcon,
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Lanjutkan Dengan Google',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return GestureDetector(
      key: const Key('link_daftar_sekarang'),
      onTap: _navigateToRegister,
      child: RichText(
        text: TextSpan(
          text: 'Belum punya akun? ',
          style: GoogleFonts.roboto(
            fontSize: 9,
            fontWeight: FontWeight.w400,
            color: AppColors.dark,
          ),
          children: [
            TextSpan(
              text: 'Daftar Sekarang',
              style: GoogleFonts.roboto(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
