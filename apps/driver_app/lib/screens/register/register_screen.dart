import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'register_upload_docs_screen.dart';

/// [RegisterScreen]
/// Layar Pendaftaran Akun Mitra Driver (Step 1: Data Diri) sesuai spesifikasi Figma:
/// - Figma/HalamanLogin/Daftar akun_step 1.png (Default form)
/// - Figma/HalamanLogin/Daftar akun_step 6.png (Keyboard input)
/// - Figma/HalamanLogin/Daftar akun_step 7.png (Terisi dengan sandi tersembunyi)
/// - Figma/HalamanLogin/Daftar akun_step 8.png (Sandi terlihat)
class RegisterScreen extends StatefulWidget {
  final VoidCallback? onBackToLogin;

  const RegisterScreen({
    super.key,
    this.onBackToLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitStep1() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Harap lengkapi seluruh kolom formulir.';
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _errorMessage = 'Format email tidak valid.';
      });
      return;
    }

    if (phone.length < 8) {
      setState(() {
        _errorMessage = 'Nomor WhatsApp tidak valid (minimal 8 digit).';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMessage = 'Kata sandi minimal harus 8 karakter.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Konfirmasi kata sandi tidak cocok.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegisterUploadDocsScreen(
          fullName: name,
          phone: phone,
          email: email,
          password: password,
        ),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width > 393 ? 373 : size.width - 20,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22.0,
                        vertical: 24.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color:
                              const Color(0xFFF1F1FD).withValues(alpha: 0.60),
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
                          // Header: Daftar Akun Driver
                          const Text(
                            'Daftar Akun Driver',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lengkapi data diri Anda untuk memulai',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.dark.withValues(alpha: 0.70),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Field 1: Nama Lengkap
                          _buildInputField(
                            controller: _nameController,
                            hintText: 'Nama Lengkap',
                            prefixIcon: Icons.person_rounded,
                            keyName: 'input_register_name',
                          ),
                          const SizedBox(height: 12),

                          // Field 2: No. WhatsApp Aktif
                          _buildInputField(
                            controller: _phoneController,
                            hintText: 'No. WhatsApp Aktif',
                            prefixIcon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                            keyName: 'input_register_phone',
                          ),
                          const SizedBox(height: 12),

                          // Field 3: Email
                          _buildInputField(
                            controller: _emailController,
                            hintText: 'Email',
                            prefixIcon: Icons.person_rounded,
                            keyboardType: TextInputType.emailAddress,
                            keyName: 'input_register_email',
                          ),
                          const SizedBox(height: 12),

                          // Field 4: Kata sandi (Min. 8 karakter)
                          _buildInputField(
                            controller: _passwordController,
                            hintText: 'Kata sandi (Min. 8 karakter)',
                            prefixIcon: Icons.lock_rounded,
                            obscureText: _obscurePassword,
                            keyName: 'input_register_password',
                            suffixIcon: GestureDetector(
                              key: const Key('toggle_register_password'),
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
                          const SizedBox(height: 12),

                          // Field 5: Ulangi Kata Sandi
                          _buildInputField(
                            controller: _confirmPasswordController,
                            hintText: 'Ulangi Kata Sandi',
                            prefixIcon: Icons.shield_outlined,
                            obscureText: _obscureConfirmPassword,
                            keyName: 'input_register_confirm_password',
                            suffixIcon: GestureDetector(
                              key: const Key(
                                  'toggle_register_confirm_password'),
                              onTap: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              child: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 19,
                                color: AppColors.dark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Error banner jika validasi gagal
                          if (_errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE83535),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Color(0xFFE83535),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFE83535),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Tombol: LANJUTKAN
                          SizedBox(
                            height: 42,
                            width: double.infinity,
                            child: ElevatedButton(
                              key: const Key('btn_lanjutkan_register'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.dark,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13.0),
                                ),
                              ),
                              onPressed: _submitStep1,
                              child: const Text(
                                'LANJUTKAN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Footer: Sudah punya akun? Masuk di sini
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
            color: Colors.black.withValues(alpha: 0.08),
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

  Widget _buildFooter() {
    return GestureDetector(
      key: const Key('link_masuk_dari_register'),
      onTap: widget.onBackToLogin ??
          () {
            Navigator.of(context).pop();
          },
      child: RichText(
        text: const TextSpan(
          text: 'Sudah punya akun? ',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w400,
            color: AppColors.dark,
          ),
          children: [
            TextSpan(
              text: 'Masuk di sini',
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
