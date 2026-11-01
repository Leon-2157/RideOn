import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rideon/core/constants/app_assets.dart';
import 'package:rideon/core/constants/app_colors.dart';
import 'country_code_model.dart';
import 'register_input_field.dart';
import 'register_phone_field.dart';
import 'register_terms_checkbox.dart';

export 'register_input_field.dart';
export 'register_phone_field.dart';
export 'register_terms_checkbox.dart';

/// View Form Pendaftaran 5 Field
class RegisterFormView extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  final CountryCode selectedCountry;
  final VoidCallback onCountryTap;

  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onToggleConfirmPassword;

  final bool isNameValid;
  final bool isEmailValid;
  final bool isPhoneValid;
  final bool isPasswordValid;
  final bool isConfirmPasswordValid;

  final bool isTermsAgreed;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onTapTerms;

  final bool isFormValid;
  final bool isLoading;
  final VoidCallback? onSubmit;

  final bool hasError;
  final String errorMessage;
  final VoidCallback onGoogleSignUp;
  final VoidCallback onTapLogin;

  const RegisterFormView({
    super.key,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.selectedCountry,
    required this.onCountryTap,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.obscureConfirmPassword,
    required this.onToggleConfirmPassword,
    required this.isNameValid,
    required this.isEmailValid,
    required this.isPhoneValid,
    required this.isPasswordValid,
    required this.isConfirmPasswordValid,
    required this.isTermsAgreed,
    required this.onTermsChanged,
    required this.onTapTerms,
    required this.isFormValid,
    required this.isLoading,
    required this.onSubmit,
    required this.hasError,
    required this.errorMessage,
    required this.onGoogleSignUp,
    required this.onTapLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header Title
        Text(
          'Daftar Akun',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Lengkapi data diri Anda untuk memulai',
          style: GoogleFonts.roboto(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 14),

        // Error Banner
        if (hasError) ...[
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
                    errorMessage,
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
          const SizedBox(height: 12),
        ],

        // Tombol Google
        _buildGoogleButton(),
        const SizedBox(height: 10),

        // Divider ATAU
        _buildOrDivider(),
        const SizedBox(height: 10),

        // Field 1: Nama Lengkap *
        RegisterInputField(
          controller: fullNameController,
          hintText: 'Nama Lengkap *',
          prefixIcon: Icons.person_rounded,
          isValid: isNameValid,
          keyName: 'input_register_name',
        ),
        const SizedBox(height: 12),

        // Field 2: Alamat Email (Opsional)
        RegisterInputField(
          controller: emailController,
          hintText: 'Alamat Email (Opsional)',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          isValid: isEmailValid,
          keyName: 'input_register_email',
        ),
        const SizedBox(height: 12),

        // Field 3: No. WhatsApp Aktif *
        RegisterPhoneField(
          phoneController: phoneController,
          selectedCountry: selectedCountry,
          onCountryTap: onCountryTap,
          isPhoneValid: isPhoneValid,
        ),
        const SizedBox(height: 12),

        // Field 4: Kata sandi *
        RegisterInputField(
          controller: passwordController,
          hintText: 'Kata sandi (Min. 8 karakter) *',
          prefixIcon: Icons.lock_rounded,
          obscureText: obscurePassword,
          isValid: isPasswordValid,
          keyName: 'input_register_password',
          suffixIcon: GestureDetector(
            onTap: onTogglePassword,
            child: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 17,
              color: AppColors.dark,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Field 5: Ulangi Kata Sandi *
        RegisterInputField(
          controller: confirmPasswordController,
          hintText: 'Ulangi Kata Sandi *',
          prefixIcon: Icons.security_rounded,
          obscureText: obscureConfirmPassword,
          isValid: isConfirmPasswordValid,
          keyName: 'input_register_confirm_password',
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
        const SizedBox(height: 12),

        // Checkbox: Syarat & Ketentuan
        RegisterTermsCheckbox(
          isTermsAgreed: isTermsAgreed,
          onTermsChanged: onTermsChanged,
          onTapTerms: onTapTerms,
        ),
        const SizedBox(height: 16),

        // Tombol: BUAT AKUN
        _buildSubmitButton(),
        const SizedBox(height: 16),

        // Footer: Sudah punya akun? Masuk di sini
        _buildFooterLoginLink(),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 42,
      width: double.infinity,
      child: ElevatedButton(
        key: const Key('btn_google_signup'),
        onPressed: isLoading ? null : onGoogleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.dark,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13.0),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppAssets.googleIcon,
              width: 17,
              height: 17,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.g_mobiledata_rounded,
                size: 20,
                color: Color(0xFFEA4335),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Daftar Dengan Google',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.dark,
              ),
            ),
          ],
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
            color: Colors.white.withValues(alpha: 0.40),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            'ATAU',
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.dark.withValues(alpha: 0.70),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.40),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 42,
      width: double.infinity,
      child: ElevatedButton(
        key: const Key('btn_buat_akun'),
        onPressed: isFormValid && !isLoading ? onSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFormValid
              ? AppColors.dark
              : const Color(0xFF9E9EAF).withValues(alpha: 0.40),
          foregroundColor: isFormValid
              ? Colors.white
              : Colors.white.withValues(alpha: 0.60),
          disabledBackgroundColor:
              const Color(0xFF9E9EAF).withValues(alpha: 0.40),
          disabledForegroundColor:
              Colors.white.withValues(alpha: 0.60),
          elevation: isFormValid ? 2 : 0,
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
            : Text(
                'BUAT AKUN',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildFooterLoginLink() {
    return GestureDetector(
      key: const Key('link_ke_halaman_masuk'),
      onTap: onTapLogin,
      child: RichText(
        text: TextSpan(
          text: 'Sudah punya akun? ',
          style: GoogleFonts.roboto(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: AppColors.dark,
          ),
          children: [
            TextSpan(
              text: 'Masuk di sini',
              style: GoogleFonts.roboto(
                fontSize: 10,
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
