import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/auth_service.dart';
import '../../data/wa_gateway_service.dart';

enum ForgotPasswordStep {
  requestOtp, // figma: Lupa kata sandi.png
  verifyOtp, // figma: verif.png, verif angka.png, verif salah.png
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
  final AuthService? authService;
  final WaGatewayService? waGatewayService;

  const ForgotPasswordScreen({
    super.key,
    this.authService,
    this.waGatewayService,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  ForgotPasswordStep _currentStep = ForgotPasswordStep.requestOtp;

  // Services
  late final AuthService _authService;
  late final WaGatewayService _waGatewayService;

  // Controllers
  final TextEditingController _identifierController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _hasOtpError = false;
  bool _hasPasswordError = false;
  String? _errorMessage;

  String _normalizedPhone = '';
  String? _matchedUserEmail;
  int _resendCountdown = 60;
  Timer? _countdownTimer;

  bool get _isEmailInput => _identifierController.text.trim().contains('@');

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _waGatewayService = widget.waGatewayService ?? WaGatewayService();
    _identifierController.addListener(_onIdentifierChanged);
  }

  void _onIdentifierChanged() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _identifierController.removeListener(_onIdentifierChanged);
    _identifierController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------
  Future<void> _sendOtp({bool isResend = false}) async {
    final text = _identifierController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan no. WhatsApp atau alamat email.';
      });
      return;
    }

    final isEmail = text.contains('@');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasOtpError = false;
    });

    if (isEmail) {
      // Alur Email: Kirim link reset password resmi via Firebase Auth
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(text)) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Format alamat email tidak valid.';
        });
        return;
      }

      try {
        await _authService.auth.sendPasswordResetEmail(email: text.toLowerCase());
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showEmailSentDialog(text.toLowerCase());
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          if (e.code == 'user-not-found') {
            _errorMessage = 'Alamat email ini belum terdaftar di RideOn.';
          } else {
            _errorMessage = e.message ?? 'Gagal mengirim email reset kata sandi.';
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal mengirim email: $e';
        });
      }
    } else {
      // Alur WhatsApp: Kirim OTP 6 Digit via WhatsApp Gateway
      final normalized = _authService.normalizePhoneNumber(text);
      if (normalized.length < 10) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Nomor WhatsApp tidak valid (minimal 10 digit).';
        });
        return;
      }

      try {
        // Cek apakah nomor terdaftar di Firestore
        final isRegistered = await _authService.isPhoneRegistered(normalized);
        if (!isRegistered) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage = 'Nomor WhatsApp belum terdaftar di RideOn. Silakan daftar terlebih dahulu.';
          });
          return;
        }

        // Cari user doc di Firestore untuk deteksi email akun
        try {
          final query = await _authService.firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: normalized)
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            final data = query.docs.first.data();
            final regEmail = (data['email'] as String?)?.trim();
            final authEmail = (data['authEmail'] as String?)?.trim();
            if (regEmail != null && regEmail.isNotEmpty) {
              _matchedUserEmail = regEmail;
            } else if (authEmail != null && authEmail.isNotEmpty) {
              _matchedUserEmail = authEmail;
            }
          }
        } catch (_) {}

        final waResult = await _waGatewayService.sendOtp(
          normalized,
          purpose: 'reset_password',
        );

        if (!mounted) return;
        if (!waResult.success) {
          setState(() {
            _isLoading = false;
            _errorMessage = waResult.error ?? 'Gagal mengirimkan kode OTP ke WhatsApp.';
          });
          return;
        }

        // Bersihkan seluruh digit OTP agar kotak kosong
        for (var c in _otpControllers) {
          c.clear();
        }

        setState(() {
          _isLoading = false;
          _normalizedPhone = normalized;
          _currentStep = ForgotPasswordStep.verifyOtp;
          _hasOtpError = false;
          _errorMessage = null;
        });

        _startCountdown();

        if (waResult.simulated && waResult.simulatedCode != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Simulasi WhatsApp: Kode OTP Anda [${waResult.simulatedCode}]'),
              duration: const Duration(seconds: 8),
              backgroundColor: const Color(0xFF6B48FC),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan: $e';
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text.trim()).join();
    if (otp.length < 6) {
      setState(() {
        _hasOtpError = true;
        _errorMessage = 'Masukkan 6 digit kode OTP WhatsApp secara lengkap.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasOtpError = false;
      _errorMessage = null;
    });

    try {
      final isValid = await _waGatewayService.verifyOtp(_normalizedPhone, otp);
      if (!mounted) return;

      if (!isValid) {
        setState(() {
          _isLoading = false;
          _hasOtpError = true;
          _errorMessage = 'Kode OTP WhatsApp tidak valid atau telah kedaluwarsa.';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _hasOtpError = false;
        _errorMessage = null;
        _currentStep = ForgotPasswordStep.resetPassword;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasOtpError = true;
        _errorMessage = 'Gagal memverifikasi OTP: $e';
      });
    }
  }

  Future<void> _saveNewPassword() async {
    final p1 = _newPasswordController.text;
    final p2 = _confirmPasswordController.text;

    if (p1.length < 6) {
      setState(() {
        _hasPasswordError = true;
        _errorMessage = 'Kata sandi minimal 6 karakter.';
      });
      return;
    }

    if (p1 != p2) {
      setState(() {
        _hasPasswordError = true;
        _errorMessage = 'Konfirmasi kata sandi baru tidak cocok.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasPasswordError = false;
      _errorMessage = null;
    });

    try {
      final result = await _waGatewayService.resetPassword(
        phoneNumber: _normalizedPhone,
        newPassword: p1,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
        return;
      }

      // Jika gateway belum memiliki serviceAccountKey.json,
      // tetapi akun pengguna memiliki email resmi di Firestore:
      if (_matchedUserEmail != null &&
          _matchedUserEmail!.isNotEmpty &&
          !_matchedUserEmail!.endsWith('@rideon.id')) {
        await _authService.auth.sendPasswordResetEmail(email: _matchedUserEmail!);
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showEmailFallbackDialog(_matchedUserEmail!);
        return;
      }

      setState(() {
        _isLoading = false;
        _hasPasswordError = true;
        _errorMessage = result['error'] ?? 'Gagal memperbarui kata sandi.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasPasswordError = true;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------
  void _showEmailSentDialog(String email) {
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
                  color: Colors.white.withValues(alpha: 0.95),
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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDE9FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: Color(0xFF6B48FC),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tautan Reset Terkirim!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kami telah mengirimkan tautan untuk mengatur ulang kata sandi ke:\n$email\n\nSilakan periksa Kotak Masuk (Inbox) atau folder Spam pada Gmail Anda, lalu klik tautan tersebut untuk membuat kata sandi baru.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: AppColors.dark.withValues(alpha: 0.75),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        key: const Key('btn_kembali_setelah_kirim_email'),
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
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: Text(
                          'KEMBALI KE HALAMAN MASUK',
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
                  color: Colors.white.withValues(alpha: 0.95),
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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDE9FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF6B48FC),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
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

  void _showEmailFallbackDialog(String email) {
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
                  color: Colors.white.withValues(alpha: 0.95),
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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDE9FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: Color(0xFF6B48FC),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Verifikasi WhatsApp Berhasil!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nomor WhatsApp Anda telah diverifikasi. Demi keamanan ganda, tautan reset kata sandi telah dikirimkan ke email terdaftar Anda:\n\n$email\n\nSilakan periksa Kotak Masuk atau folder Spam pada Gmail Anda untuk menyelesaikan penggantian kata sandi.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: AppColors.dark.withValues(alpha: 0.75),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: Text(
                          'KEMBALI KE HALAMAN MASUK',
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
    final isEmail = _isEmailInput;

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

        // Error message banner
        if (_errorMessage != null) ...[
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
                    _errorMessage!,
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
          controller: _identifierController,
          hintText: 'No. WhatsApp / Email',
          prefixIcon: isEmail ? Icons.email_outlined : Icons.person_rounded,
          keyName: 'input_forgot_identifier',
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        ),
        const SizedBox(height: 18),

        SizedBox(
          height: 44,
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('btn_kirim_kode_otp'),
            onPressed: _isLoading ? null : () => _sendOtp(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.dark.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    isEmail ? Icons.mail_outline_rounded : Icons.send_rounded,
                    size: 16,
                  ),
            label: Text(
              _isLoading
                  ? 'MEMPROSES...'
                  : (isEmail ? 'KIRIM TAUTAN RESET KE EMAIL' : 'KIRIM KODE OTP'),
              style: GoogleFonts.roboto(
                fontSize: 11.5,
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
          'Masukkan 6 digit kode OTP yang kami kirimkan ke WhatsApp $_normalizedPhone.',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 11.5,
            color: AppColors.dark.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),

        // Error alert banner if invalid OTP (verif salah.png)
        if (_hasOtpError || _errorMessage != null) ...[
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
                    _errorMessage ?? 'Kode OTP WhatsApp tidak valid.',
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
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace &&
                        _otpControllers[i].text.isEmpty &&
                        i > 0) {
                      _otpFocusNodes[i - 1].requestFocus();
                    }
                  },
                  child: TextField(
                    key: Key('otp_box_$i'),
                    controller: _otpControllers[i],
                    focusNode: _otpFocusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                        _otpFocusNodes[i + 1].requestFocus();
                      } else if (val.isEmpty && i > 0) {
                        _otpFocusNodes[i - 1].requestFocus();
                      }
                      if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                        _verifyOtp();
                      }
                    },
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),

        // Countdown timer & Resend Button
        if (_resendCountdown > 0) ...[
          Text(
            'Kode kadaluarsa dalam 0:${_resendCountdown.toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: AppColors.dark.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
        ] else ...[
          GestureDetector(
            onTap: _isLoading ? null : () => _sendOtp(isResend: true),
            child: Text(
              'KIRIM ULANG KODE OTP VIA WA',
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B48FC),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),

        // Button: KONFIRMASI / VERIFIKASI
        SizedBox(
          height: 44,
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('btn_verifikasi_otp'),
            onPressed: _isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.dark.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 16),
            label: Text(
              _isLoading ? 'MEMVERIFIKASI...' : 'KONFIRMASI',
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

        if (_hasPasswordError || _errorMessage != null) ...[
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
                    _errorMessage ?? 'Kata sandi minimal 6 karakter dan harus sama.',
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
            onPressed: _isLoading ? null : _saveNewPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.dark.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: _isLoading
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
              _isLoading ? 'MENYIMPAN...' : 'SIMPAN SANDI BARU',
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
