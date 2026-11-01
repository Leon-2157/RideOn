import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import 'reset_password_screen.dart';

/// [OtpVerificationScreen]
/// Layar Verifikasi WhatsApp OTP Mitra Driver sesuai spesifikasi desain Figma:
/// - Figma/HalamanLogin/verif.png (Tampilan default 6 titik)
/// - Figma/HalamanLogin/verif angka.png (Input 6 digit angka)
/// - Figma/HalamanLogin/verif salah.png (Banner error OTP tidak valid)
class OtpVerificationScreen extends StatefulWidget {
  final String? identifier;
  final VoidCallback? onBackToLogin;
  final VoidCallback? onVerified;
  final bool showErrorBanner;

  const OtpVerificationScreen({
    super.key,
    this.identifier,
    this.onBackToLogin,
    this.onVerified,
    this.showErrorBanner = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late bool _hasError;
  int _secondsRemaining = 300; // 5 menit (5:00)
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _hasError = widget.showErrorBanner;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final secondsStr = seconds < 10 ? '0$seconds' : '$seconds';
    return '$minutes:$secondsStr';
  }

  void _submit() {
    // Jika masih tahap implementasi Figma, navigasi langsung didukung
    if (widget.onVerified != null) {
      widget.onVerified!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ResetPasswordScreen(),
        ),
      );
    }
  }

  void _handleBack() {
    if (widget.onBackToLogin != null) {
      widget.onBackToLogin!();
    } else {
      Navigator.of(context).pop();
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
              // Badge Icon WhatsApp
              _buildTopBadge(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.chat_bubble_rounded,
                      size: 24,
                      color: AppColors.dark,
                    ),
                    Positioned(
                      top: 4,
                      left: 5,
                      child: Transform.rotate(
                        angle: -0.2,
                        child: const Icon(
                          Icons.phone_rounded,
                          size: 11,
                          color: Color(0xFFC6BCFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Verifikasi WhatsApp',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                'Masukkan OTP yang dikirim ke WhatsApp Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.dark.withValues(alpha: 0.70),
                ),
              ),
              const SizedBox(height: 14),

              // Error banner matching Figma: verif salah.png
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
                          'Kode OTP WhatsApp tidak valid.',
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

              // Input OTP 6 Slot Box
              _buildOtpInputBox(),
              const SizedBox(height: 14),

              // Countdown text: Kode kadaluarsa dalam 5:00
              Column(
                children: [
                  Text(
                    'Kode kadaluarsa dalam',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.dark.withValues(alpha: 0.70),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimer(_secondsRemaining),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Button: VERIFIKASI
              SizedBox(
                height: 42,
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('btn_verifikasi_otp'),
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
                        Icons.send_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'VERIFIKASI',
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
              const SizedBox(height: 24),

              // Kembali ke halaman Masuk
              GestureDetector(
                key: const Key('link_kembali_ke_login'),
                onTap: _handleBack,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: 14,
                      color: AppColors.dark,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Kembali ke halaman Masuk',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInputBox() {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            // TextField tak terlihat untuk menerima ketikan pengguna
            Opacity(
              opacity: 0.0,
              child: TextField(
                key: const Key('input_otp_code'),
                controller: _otpController,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  setState(() {
                    if (_hasError) _hasError = false;
                  });
                },
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
            // Tampilan visual 6 slot (titik atau angka)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                final text = _otpController.text;
                final isFilled = index < text.length;
                if (isFilled) {
                  return Text(
                    text[index],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  );
                } else {
                  return const Text(
                    '●',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.dark,
                    ),
                  );
                }
              }),
            ),
          ],
        ),
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
