import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_colors.dart';
import 'forgot_password_wrapper.dart';

/// Step 3: Form Pembuatan Kata Sandi Baru (Figma: sandi baru.png)
class ResetPasswordCard extends StatelessWidget {
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool obscureNewPassword;
  final VoidCallback onToggleNewPassword;
  final bool obscureConfirmPassword;
  final VoidCallback onToggleConfirmPassword;
  final bool hasPasswordError;
  final String? errorMessage;
  final bool isLoading;
  final VoidCallback onSaveNewPassword;
  final VoidCallback onBackToLogin;

  const ResetPasswordCard({
    super.key,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.obscureNewPassword,
    required this.onToggleNewPassword,
    required this.obscureConfirmPassword,
    required this.onToggleConfirmPassword,
    required this.hasPasswordError,
    this.errorMessage,
    required this.isLoading,
    required this.onSaveNewPassword,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordWrapper(
      children: [
        const ForgotPasswordCircleIcon(icon: Icons.shield_outlined),
        const SizedBox(height: 16),

        Text(
          'Buat Kata Sandi Baru',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pastikan sandi baru Anda kuat dan mudah diingat',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 11.5,
            color: AppColors.dark.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),

        if (hasPasswordError || errorMessage != null) ...[
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
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFE83535),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage ??
                        'Kata sandi minimal 6 karakter dan harus sama.',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE83535),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        ForgotPasswordInput(
          controller: newPasswordController,
          hintText: 'Kata sandi Baru',
          prefixIcon: Icons.lock_rounded,
          obscureText: obscureNewPassword,
          keyName: 'input_new_password',
          suffixIcon: GestureDetector(
            onTap: onToggleNewPassword,
            child: Icon(
              obscureNewPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 17,
              color: AppColors.dark,
            ),
          ),
        ),
        const SizedBox(height: 12),

        ForgotPasswordInput(
          controller: confirmPasswordController,
          hintText: 'Konfirmasi Kata Sandi Baru',
          prefixIcon: Icons.lock_open_rounded,
          obscureText: obscureConfirmPassword,
          keyName: 'input_confirm_new_password',
          suffixIcon: GestureDetector(
            onTap: onToggleConfirmPassword,
            child: Icon(
              obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 17,
              color: AppColors.dark,
            ),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          height: 44,
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('btn_simpan_sandi_baru'),
            onPressed: isLoading ? null : onSaveNewPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.dark.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 16),
            label: Text(
              isLoading ? 'MENYIMPAN...' : 'SIMPAN SANDI BARU',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        BackToLoginLink(onTap: onBackToLogin),
      ],
    );
  }
}
