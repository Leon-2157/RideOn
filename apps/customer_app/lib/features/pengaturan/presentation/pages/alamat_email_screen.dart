import 'dart:async';
import 'package:flutter/material.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/data/email_otp_service.dart';
import '../widgets/sub_header_widget.dart';
import '../modules/alamat_email/alamat_email_form_card.dart';
import '../modules/alamat_email/alamat_email_logic.dart';
import '../modules/alamat_email/alamat_email_otp_card.dart';
import '../modules/alamat_email/email_success_dialog.dart';

export '../modules/alamat_email/alamat_email_form_card.dart';
export '../modules/alamat_email/alamat_email_logic.dart';
export '../modules/alamat_email/alamat_email_otp_card.dart';
export '../modules/alamat_email/email_success_dialog.dart';
export '../modules/alamat_email/email_verification_dialog.dart';

class AlamatEmailScreen extends StatefulWidget {
  final String currentEmail;
  final String userPhone;
  final bool isEmailVerified;
  final EmailOtpService? emailOtpService;
  final AuthService? authService;

  const AlamatEmailScreen({
    super.key,
    this.currentEmail = '',
    this.userPhone = '',
    this.isEmailVerified = true,
    this.emailOtpService,
    this.authService,
  });

  @override
  State<AlamatEmailScreen> createState() => _AlamatEmailScreenState();
}

class _AlamatEmailScreenState extends State<AlamatEmailScreen> {
  final _passwordController = TextEditingController();
  final _oldEmailController = TextEditingController();
  final _newEmailController = TextEditingController();

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  late final AlamatEmailLogic _logic;

  bool _obscurePassword = true;
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasOtpError = false;

  int _countdownSeconds = 60;
  Timer? _countdownTimer;
  String _targetEmail = '';

  bool get _hasCurrentEmail =>
      widget.currentEmail.trim().isNotEmpty &&
      widget.currentEmail.trim() != 'Belum ditambahkan' &&
      !widget.currentEmail.endsWith('@rideon.id') &&
      widget.isEmailVerified;

  @override
  void initState() {
    super.initState();
    _logic = AlamatEmailLogic(
      authService: widget.authService,
      emailOtpService: widget.emailOtpService,
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _oldEmailController.dispose();
    _newEmailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdownSeconds = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        if (mounted) {
          setState(() => _countdownSeconds--);
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _handleBackToForm() {
    _countdownTimer?.cancel();
    for (final c in _otpControllers) {
      c.clear();
    }
    setState(() {
      _isOtpSent = false;
      _isLoading = false;
      _hasError = false;
      _hasOtpError = false;
      _errorMessage = null;
    });
  }

  Future<void> _handleSendOtp() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _hasOtpError = false;
      _errorMessage = null;
    });

    try {
      final validNewEmail = await _logic.validateAndAuthenticate(
        password: _passwordController.text.trim(),
        rawOldEmail: _oldEmailController.text.trim().toLowerCase(),
        rawNewEmail: _newEmailController.text.trim().toLowerCase(),
        currentEmail: widget.currentEmail,
        hasCurrentEmail: _hasCurrentEmail,
        userPhone: widget.userPhone,
      );

      _targetEmail = validNewEmail;
      final result = await _logic.sendOtp(_targetEmail);

      if (!result.success) {
        throw result.error ?? 'Gagal mengirimkan kode OTP ke email.';
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });
      _startCountdown();

      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && _otpFocusNodes[0].canRequestFocus) {
          _otpFocusNodes[0].requestFocus();
        }
      });

      if (result.devOtp != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kode OTP (Dev/Simulasi): [${result.devOtp}]'),
            backgroundColor: const Color(0xFF6B48FC),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleResendOtp() async {
    if (_countdownSeconds > 0 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _hasOtpError = false;
      _errorMessage = null;
    });

    try {
      final result = await _logic.sendOtp(_targetEmail);
      if (!result.success) {
        throw result.error ?? 'Gagal mengirim ulang kode OTP.';
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      _startCountdown();

      if (result.devOtp != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kode OTP Baru (Dev): [${result.devOtp}]'),
            backgroundColor: const Color(0xFF6B48FC),
            duration: const Duration(seconds: 8),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode OTP baru telah dikirimkan ke email!'),
            backgroundColor: Color(0xFF6B48FC),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleVerifyAndSave() async {
    final code = _otpControllers.map((c) => c.text.trim()).join();

    setState(() {
      _isLoading = true;
      _hasError = false;
      _hasOtpError = false;
      _errorMessage = null;
    });

    try {
      await _logic.verifyOtpAndSave(
        targetEmail: _targetEmail,
        code: code,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      await EmailSuccessDialog.show(
        context,
        email: _targetEmail,
        isUpdate: _hasCurrentEmail,
        onFinished: () {
          Navigator.of(context).pop(_targetEmail);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasOtpError = true;
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          buildSubHeader(context, 'Alamat Email'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (!_isOtpSent)
                    AlamatEmailFormCard(
                      passwordController: _passwordController,
                      oldEmailController: _oldEmailController,
                      newEmailController: _newEmailController,
                      obscurePassword: _obscurePassword,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      hasCurrentEmail: _hasCurrentEmail,
                      currentEmail: widget.currentEmail,
                      isLoading: _isLoading,
                      hasError: _hasError,
                      errorMessage: _errorMessage,
                      onSubmit: _handleSendOtp,
                    )
                  else
                    AlamatEmailOtpCard(
                      targetEmail: _targetEmail,
                      otpControllers: _otpControllers,
                      otpFocusNodes: _otpFocusNodes,
                      countdownSeconds: _countdownSeconds,
                      isLoading: _isLoading,
                      hasOtpError: _hasOtpError,
                      onResend: _handleResendOtp,
                      onVerifyAndSave: _handleVerifyAndSave,
                      onBackToForm: _handleBackToForm,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
