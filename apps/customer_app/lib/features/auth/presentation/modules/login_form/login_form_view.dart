import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

/// Form email/password + error banner + tombol MASUK.
///
/// Tampilan murni — tidak mengandung logika/state.
/// Semua state dikelola oleh [_LoginScreenState] di login_screen.dart.
class LoginFormView extends StatelessWidget {
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool hasLoginError;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;

  const LoginFormView({
    super.key,
    required this.identifierController,
    required this.passwordController,
    required this.obscurePassword,
    required this.hasLoginError,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInputField(
          controller: identifierController,
          hintText: 'No. WhatsApp / Email',
          prefixIcon: Icons.person_rounded,
          keyboardType: TextInputType.emailAddress,
          keyName: 'input_login_identifier',
        ),
        const SizedBox(height: 15),
        _buildInputField(
          controller: passwordController,
          hintText: 'Kata Sandi',
          prefixIcon: Icons.lock_rounded,
          obscureText: obscurePassword,
          keyName: 'input_login_password',
          suffixIcon: GestureDetector(
            onTap: onToggleObscure,
            child: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 17,
              color: AppColors.dark,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            key: const Key('link_lupa_kata_sandi'),
            onTap: onForgotPassword,
            child: const Text(
              'Lupa kata sandi?',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.dark,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (hasLoginError) ...[
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
                Icon(Icons.error_outline_rounded,
                    color: Color(0xFFE83535), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Email/WhatsApp atau kata sandi yang Anda masukkan salah.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
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
        _buildPrimaryButton(),
      ],
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
          Icon(prefixIcon, size: 19, color: AppColors.dark),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: keyName != null ? Key(keyName) : null,
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.dark,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: hintText,
                hintStyle: TextStyle(
                  fontFamily: 'Roboto',
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
        onPressed: onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dark,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13.0),
          ),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
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
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
