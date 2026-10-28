import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

enum ForgotPasswordStep {
  requestOtp, // figma: Lupa kata sandi.png
  verifyOtp,  // figma: verif.png, verif angka.png, verif salah.png
  resetPassword, // figma: sandi baru.png
}

/// Screen Alur Lupa Kata Sandi RideOn
/// Strictly implements:
/// - figma/HalamanLogin/Lupa kata sandi.png
/// - figma/HalamanLogin/verif.png
/// - figma/HalamanLogin/verif angka.png
/// - figma/HalamanLogin/verif salah.png
/// - figma/HalamanLogin/sandi baru.png
/// - figma/HalamanLogin/ubah sandi success.png
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  ForgotPasswordStep _currentStep = ForgotPasswordStep.requestOtp;

  // Controllers
  final TextEditingController _identifierController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasOtpError = false;
  bool _hasPasswordError = false;

  @override
  void dispose() {
    _identifierController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final text = _identifierController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan no. WhatsApp atau email')),
      );
      return;
    }
    // Prefill OTP for testing/simulation
    _otpControllers[0].text = '1';
    _otpControllers[1].text = '2';
    _otpControllers[2].text = '3';
    _otpControllers[3].text = '4';
    _otpControllers[4].text = '5';
    _otpControllers[5].text = '6';

    setState(() {
      _currentStep = ForgotPasswordStep.verifyOtp;
      _hasOtpError = false;
    });
  }

  void _verifyOtp() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() {
        _hasOtpError = true;
      });
      return;
    }

    setState(() {
      _hasOtpError = false;
      _currentStep = ForgotPasswordStep.resetPassword;
    });
  }

  void _saveNewPassword() {
    final p1 = _newPasswordController.text;
    final p2 = _confirmPasswordController.text;

    if (p1.length < 6 || p1 != p2) {
      setState(() {
        _hasPasswordError = true;
      });
      return;
    }

    setState(() {
      _hasPasswordError = false;
    });

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF1F1FD).withValues(alpha: 0.8),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      offset: const Offset(0, 4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Berhasil Diubah!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kata sandi akun Anda telah berhasil diperbarui. Silakan masuk menggunakan kata sandi yang baru.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: AppColors.dark.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        key: const Key('btn_masuk_sekarang_reset_success'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.of(context).pop(); // Pop back to LoginScreen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: Text(
                          'MASUK SEKARANG',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
                child: _buildCurrentStepCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepCard() {
    switch (_currentStep) {
      case ForgotPasswordStep.requestOtp:
        return _buildRequestOtpCard();
      case ForgotPasswordStep.verifyOtp:
        return _buildVerifyOtpCard();
      case ForgotPasswordStep.resetPassword:
        return _buildResetPasswordCard();
    }
  }

  // ---------------------------------------------------------------------------
  // Step 1: Lupa kata sandi.png
  // ---------------------------------------------------------------------------
  Widget _buildRequestOtpCard() {
    return _buildGlassCardWrapper(
      children: [
        // Circular Key Icon
        _buildCircleIcon(Icons.key_rounded),
        const SizedBox(height: 16),

        Text(
          'Lupa Kata Sandi?',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masukkan nomor WhatsApp atau alamat email yang terdaftar di akun RideOn Anda.',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 11.5,
            color: AppColors.dark.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        _buildInputField(
          controller: _identifierController,
          hintText: 'No. WhatsApp / Email',
          prefixIcon: Icons.person_rounded,
          keyName: 'input_forgot_identifier',
        ),
        const SizedBox(height: 18),

        SizedBox(
          height: 44,
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('btn_kirim_kode_otp'),
            onPressed: _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(
              'KIRIM KODE OTP',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildBackToLoginLink(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: verif.png / verif angka.png / verif salah.png
  // ---------------------------------------------------------------------------
  Widget _buildVerifyOtpCard() {
    return _buildGlassCardWrapper(
      children: [
        // WhatsApp Icon Circle
        _buildCircleIcon(Icons.mark_chat_unread_rounded),
        const SizedBox(height: 16),

        Text(
          'Verifikasi WhatsApp',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Masukkan OTP yang dikirim ke WhatsApp Anda.',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 11.5,
            color: AppColors.dark.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),

        // Error alert banner if invalid OTP (verif salah.png)
        if (_hasOtpError) ...[
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
                    'Kode OTP WhatsApp tidak valid.',
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

        // 6-digit OTP Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: const Alignment(-0.94, -0.69),
              end: const Alignment(0.94, 0.78),
              stops: const [0.45, 1.0],
              colors: [
                AppColors.primary.withValues(alpha: 0.20),
                Colors.white.withValues(alpha: 0.20),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (i) {
              return SizedBox(
                width: 38,
                height: 42,
                child: TextField(
                  key: Key('otp_box_$i'),
                  controller: _otpControllers[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && i < 5) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),

        // Countdown timer
        Text(
          'Kode kadaluarsa dalam 5:00',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 11,
            color: AppColors.dark.withValues(alpha: 0.75),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),

        // Button: KONFIRMASI / VERIFIKASI
        SizedBox(
          height: 44,
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('btn_verifikasi_otp'),
            onPressed: _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(
              'KONFIRMASI',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildBackToLoginLink(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: sandi baru.png
  // ---------------------------------------------------------------------------
  Widget _buildResetPasswordCard() {
    return _buildGlassCardWrapper(
      children: [
        _buildCircleIcon(Icons.shield_outlined),
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

        if (_hasPasswordError) ...[
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

        _buildInputField(
          controller: _newPasswordController,
          hintText: 'Kata sandi Baru',
          prefixIcon: Icons.lock_rounded,
          obscureText: _obscureNewPassword,
          keyName: 'input_new_password',
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            child: Icon(
              _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 17,
              color: AppColors.dark,
            ),
          ),
        ),
        const SizedBox(height: 12),

        _buildInputField(
          controller: _confirmPasswordController,
          hintText: 'Konfirmasi Kata Sandi Baru',
          prefixIcon: Icons.lock_open_rounded,
          obscureText: _obscureConfirmPassword,
          keyName: 'input_confirm_new_password',
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            child: Icon(
              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
            onPressed: _saveNewPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.save_rounded, size: 16),
            label: Text(
              'SIMPAN SANDI BARU',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildBackToLoginLink(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Widget _buildGlassCardWrapper({required List<Widget> children}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 26.0),
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
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildCircleIcon(IconData icon) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFE2DCFE),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.dark, size: 24),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    String? keyName,
    bool obscureText = false,
    Widget? suffixIcon,
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

  Widget _buildBackToLoginLink() {
    return GestureDetector(
      key: const Key('link_kembali_ke_masuk'),
      onTap: () => Navigator.of(context).pop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_back_rounded, size: 14, color: AppColors.dark),
          const SizedBox(width: 4),
          Text(
            'Kembali ke halaman Masuk',
            style: GoogleFonts.roboto(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}
