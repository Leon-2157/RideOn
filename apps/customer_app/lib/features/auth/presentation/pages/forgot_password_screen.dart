import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/auth_service.dart';
import '../../data/wa_gateway_service.dart';
import '../modules/forgot_password/email_fallback_dialog.dart';
import '../modules/forgot_password/forgot_password_logic.dart';
import '../modules/forgot_password/request_otp_card.dart';
import '../modules/forgot_password/reset_password_card.dart';
import '../modules/forgot_password/reset_password_email_sent_dialog.dart';
import '../modules/forgot_password/reset_password_success_dialog.dart';
import '../modules/forgot_password/verify_otp_card.dart';

export '../modules/forgot_password/email_fallback_dialog.dart';
export '../modules/forgot_password/forgot_password_logic.dart';
export '../modules/forgot_password/forgot_password_wrapper.dart';
export '../modules/forgot_password/request_otp_card.dart';
export '../modules/forgot_password/reset_password_card.dart';
export '../modules/forgot_password/reset_password_email_sent_dialog.dart';
export '../modules/forgot_password/reset_password_success_dialog.dart';
export '../modules/forgot_password/verify_otp_card.dart';

enum ForgotPasswordStep {
  requestOtp, // figma: Lupa kata sandi.png
  verifyOtp, // figma: verif.png, verif angka.png, verif salah.png
  resetPassword, // figma: sandi baru.png
}

/// Screen Alur Lupa Kata Sandi RideOn
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
  late final ForgotPasswordLogic _logic;

  final TextEditingController _identifierController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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

  bool get _isEmailInput => _logic.isEmail(_identifierController.text);

  @override
  void initState() {
    super.initState();
    _logic = ForgotPasswordLogic(
      authService: widget.authService,
      waGatewayService: widget.waGatewayService,
    );
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

  Future<void> _sendOtp({bool isResend = false}) async {
    final text = _identifierController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan no. WhatsApp atau alamat email.';
      });
      return;
    }

    final isEmail = _logic.isEmail(text);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasOtpError = false;
    });

    if (isEmail) {
      if (!_logic.isValidEmail(text)) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Format alamat email tidak valid.';
        });
        return;
      }

      try {
        await _logic.sendEmailReset(text);
        if (!mounted) return;
        setState(() => _isLoading = false);
        ResetPasswordEmailSentDialog.show(context, email: text.toLowerCase());
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
      final normalized = _logic.normalizePhone(text);
      if (normalized.length < 10) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Nomor WhatsApp tidak valid (minimal 10 digit).';
        });
        return;
      }

      try {
        final isRegistered = await _logic.isPhoneRegistered(normalized);
        if (!isRegistered) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Nomor WhatsApp belum terdaftar di RideOn. Silakan daftar terlebih dahulu.';
          });
          return;
        }

        _matchedUserEmail = await _logic.lookupMatchedEmail(normalized);
        final waResult = await _logic.sendWhatsAppOtp(normalized);

        if (!mounted) return;
        if (!waResult.success) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                waResult.error ?? 'Gagal mengirimkan kode OTP ke WhatsApp.';
          });
          return;
        }

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
              content: Text(
                  'Simulasi WhatsApp: Kode OTP Anda [${waResult.simulatedCode}]'),
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
      final isValid = await _logic.verifyOtp(_normalizedPhone, otp);
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
      final result = await _logic.resetPassword(
        normalizedPhone: _normalizedPhone,
        newPassword: p1,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() => _isLoading = false);
        ResetPasswordSuccessDialog.show(context);
        return;
      }

      if (_matchedUserEmail != null &&
          _matchedUserEmail!.isNotEmpty &&
          !_matchedUserEmail!.endsWith('@rideon.id')) {
        await _logic.sendEmailReset(_matchedUserEmail!);
        if (!mounted) return;
        setState(() => _isLoading = false);
        EmailFallbackDialog.show(context, email: _matchedUserEmail!);
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

  Widget _buildCurrentStepCard() {
    switch (_currentStep) {
      case ForgotPasswordStep.requestOtp:
        return RequestOtpCard(
          identifierController: _identifierController,
          isEmail: _isEmailInput,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          onSendOtp: () => _sendOtp(),
          onBackToLogin: () => Navigator.of(context).pop(),
        );
      case ForgotPasswordStep.verifyOtp:
        return VerifyOtpCard(
          normalizedPhone: _normalizedPhone,
          hasOtpError: _hasOtpError,
          errorMessage: _errorMessage,
          otpControllers: _otpControllers,
          otpFocusNodes: _otpFocusNodes,
          resendCountdown: _resendCountdown,
          isLoading: _isLoading,
          onVerify: _verifyOtp,
          onResendOtp: () => _sendOtp(isResend: true),
          onBackToLogin: () => Navigator.of(context).pop(),
        );
      case ForgotPasswordStep.resetPassword:
        return ResetPasswordCard(
          newPasswordController: _newPasswordController,
          confirmPasswordController: _confirmPasswordController,
          obscureNewPassword: _obscureNewPassword,
          onToggleNewPassword: () =>
              setState(() => _obscureNewPassword = !_obscureNewPassword),
          obscureConfirmPassword: _obscureConfirmPassword,
          onToggleConfirmPassword: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword),
          hasPasswordError: _hasPasswordError,
          errorMessage: _errorMessage,
          isLoading: _isLoading,
          onSaveNewPassword: _saveNewPassword,
          onBackToLogin: () => Navigator.of(context).pop(),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
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
}
