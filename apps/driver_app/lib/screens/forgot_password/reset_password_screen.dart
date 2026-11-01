import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'reset_password_success_screen.dart';

/// [ResetPasswordScreen]
/// Layar Buat Kata Sandi Baru Mitra Driver sesuai spesifikasi desain Figma:
/// - Figma/HalamanLogin/sandi baru.png (Default form)
/// - Figma/HalamanLogin/sandi baru 1.png (Error: Sandi tidak sesuai)
/// - Figma/HalamanLogin/sandi baru 3.png (Sandi tersembunyi)
/// - Figma/HalamanLogin/sandi baru 4.png (Sandi terlihat)
class ResetPasswordScreen extends StatefulWidget {
  final VoidCallback? onBackToLogin;
  final VoidCallback? onPasswordSaved;
  final bool showErrorBanner;

  const ResetPasswordScreen({
    super.key,
    this.onBackToLogin,
    this.onPasswordSaved,
    this.showErrorBanner = false,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  late bool _hasError;

  @override
  void initState() {
    super.initState();
    _hasError = widget.showErrorBanner;
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    // Jika kata sandi diisi dan berbeda, tampilkan error banner sesuai Figma sandi baru 1.png
    if (newPass.isNotEmpty && confirmPass.isNotEmpty && newPass != confirmPass) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    if (widget.onPasswordSaved != null) {
      widget.onPasswordSaved!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ResetPasswordSuccessScreen(),
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
          padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 26.0),
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
              // Badge Icon Perisai (Shield)
              _buildTopBadge(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      size: 24,
                      color: AppColors.dark,
                    ),
                    Positioned(
                      top: 8,
                      child: Container(
                        width: 4,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC6BCFF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Buat Kata Sandi Baru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                'Pastikan sandi baru Anda kuat dan mudah diingat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.dark.withValues(alpha: 0.70),
                ),
              ),
              const SizedBox(height: 14),

              // Error banner matching Figma sandi baru 1.png
              if (_hasError) ...[
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
                          'Sandi tidak sesuai.',
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
                const SizedBox(height: 14),
              ],

              // Input 1: Kata sandi Baru
              _buildPasswordField(
                controller: _newPasswordController,
                hintText: 'Kata sandi Baru',
                prefixIcon: Icons.lock_rounded,
                obscureText: _obscureNewPassword,
                keyName: 'input_new_password',
                toggleKeyName: 'toggle_new_password',
                onToggleVisibility: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Input 2: Konfirmasi Kata Sandi Baru
              _buildPasswordField(
                controller: _confirmPasswordController,
                hintText: 'Konfirmasi Kata Sandi Baru',
                prefixIcon: Icons.lock_open_rounded,
                obscureText: _obscureConfirmPassword,
                keyName: 'input_confirm_new_password',
                toggleKeyName: 'toggle_confirm_password',
                onToggleVisibility: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Button: SIMPAN SANDI BARU
              SizedBox(
                height: 42,
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('btn_simpan_sandi_baru'),
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13.0),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.save_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'SIMPAN SANDI BARU',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required bool obscureText,
    required String keyName,
    required String toggleKeyName,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      height: 44,
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
              key: Key(keyName),
              controller: controller,
              obscureText: obscureText,
              onChanged: (_) {
                if (_hasError) {
                  setState(() {
                    _hasError = false;
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
          GestureDetector(
            key: Key(toggleKeyName),
            onTap: onToggleVisibility,
            child: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 19,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBadge({required Widget child}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE2DCFE),
            Color(0xFFC6BCFF),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
