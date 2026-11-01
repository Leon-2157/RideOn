import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/driver_service.dart';
import 'radar/radar_screen.dart';
import 'register/register_screen.dart';
import 'forgot_password/forgot_password_screen.dart';

/// [LoginScreen]
/// Implementasi Halaman Login Mitra Driver sesuai spesifikasi desain Figma:
/// - Figma/HalamanLogin/Login Drive rr.png (Tampilan default)
/// - Figma/HalamanLogin/Login Driver masuk.png (Input identifier)
/// - Figma/HalamanLogin/Login Driver masuk buka mata.png (Tampilkan sandi)
/// - Figma/HalamanLogin/Login Driver masuk 2.png (Sandi tersembunyi)
/// - Figma/HalamanLogin/Login kata sandi salah.png (Banner error validasi/autentikasi)
class LoginScreen extends StatefulWidget {
  final DriverService? driverService;
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onRegister;
  final bool showErrorBanner;

  const LoginScreen({
    super.key,
    this.driverService,
    this.onLoginSuccess,
    this.onForgotPassword,
    this.onRegister,
    this.showErrorBanner = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  late bool _hasLoginError;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _hasLoginError = widget.showErrorBanner;
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleGoogleLogin() {
    if (_hasLoginError) {
      setState(() {
        _hasLoginError = false;
      });
    }
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RadarScreen(),
        ),
      );
    }
  }

  void _submitLogin() {
    if (_hasLoginError) {
      setState(() {
        _hasLoginError = false;
      });
    }
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RadarScreen(),
        ),
      );
    }
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
                'assets/images/logo_white_clean.png',
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
                  key: const Key('toggle_password_visibility'),
                  onTap: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 19,
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
                  onTap: widget.onForgotPassword ??
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                  child: const Text(
                    'Lupa kata sandi?',
                    style: TextStyle(
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
                  child: const Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFE83535),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Email/WhatsApp atau kata sandi yang Anda masukkan salah.',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE83535),
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
              onChanged: (_) {
                if (_hasLoginError) {
                  setState(() {
                    _hasLoginError = false;
                  });
                }
              },
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.dark,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: hintText,
                hintStyle: TextStyle(
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
        onPressed: _isLoading ? null : _submitLogin,
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
            : const Text(
                'MASUK',
                style: TextStyle(
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
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: AppColors.dark.withValues(alpha: 0.70),
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
                'assets/images/google_icon.png',
                width: 16,
                height: 16,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.g_mobiledata_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Lanjutkan Dengan Google',
                style: TextStyle(
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
      onTap: widget.onRegister ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RegisterScreen(),
              ),
            );
          },
      child: RichText(
        text: const TextSpan(
          text: 'Belum punya akun? ',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w400,
            color: AppColors.dark,
          ),
          children: [
            TextSpan(
              text: 'Daftar Sekarang',
              style: TextStyle(
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
