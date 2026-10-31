import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../main/presentation/pages/main_screen.dart';
import '../../data/auth_service.dart';
import '../../data/wa_gateway_service.dart';
import '../modules/register/country_code_model.dart';
import '../modules/register/country_picker_sheet.dart';
import '../modules/register/fallback_sms_dialog.dart';
import '../modules/register/register_form_view.dart';
import '../modules/register/register_logic.dart';
import '../modules/register/register_otp_view.dart';
import '../modules/register/register_success_dialog.dart';
import '../modules/register/terms_bottom_sheet.dart';

export '../modules/register/country_code_model.dart';
export '../modules/register/country_picker_sheet.dart';
export '../modules/register/fallback_sms_dialog.dart';
export '../modules/register/register_form_view.dart';
export '../modules/register/register_logic.dart';
export '../modules/register/register_otp_view.dart';
export '../modules/register/register_success_dialog.dart';
export '../modules/register/terms_bottom_sheet.dart';

/// Screen Pendaftaran Akun Customer RideOn (Slim Coordinator)
class RegisterScreen extends StatefulWidget {
  final AuthService? authService;
  final WaGatewayService? waGatewayService;

  const RegisterScreen({
    super.key,
    this.authService,
    this.waGatewayService,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  RegisterStep _currentStep = RegisterStep.form;
  OtpDeliveryMode _otpDeliveryMode = OtpDeliveryMode.whatsapp;
  late final RegisterLogic _logic;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  CountryCode _selectedCountry = supportedCountries[0];

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isTermsAgreed = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  bool _hasOtpError = false;
  String _otpErrorMessage = '';
  int _resendCountdown = 60;
  Timer? _countdownTimer;
  String? _verificationId;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    _logic = RegisterLogic(
      authService: widget.authService,
      waGatewayService: widget.waGatewayService,
    );

    _fullNameController.addListener(_onFormFieldChanged);
    _emailController.addListener(_onFormFieldChanged);
    _phoneController.addListener(_onFormFieldChanged);
    _passwordController.addListener(_onFormFieldChanged);
    _confirmPasswordController.addListener(_onFormFieldChanged);
  }

  void _onFormFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _fullNameController.removeListener(_onFormFieldChanged);
    _emailController.removeListener(_onFormFieldChanged);
    _phoneController.removeListener(_onFormFieldChanged);
    _passwordController.removeListener(_onFormFieldChanged);
    _confirmPasswordController.removeListener(_onFormFieldChanged);

    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _isNameValid => _logic.isNameValid(_fullNameController.text);
  bool get _isEmailValid => _logic.isEmailValid(_emailController.text);
  bool get _isPhoneValid => _logic.isPhoneValid(_phoneController.text);
  bool get _isPasswordValid => _logic.isPasswordValid(_passwordController.text);
  bool get _isConfirmPasswordValid => _logic.isConfirmPasswordValid(
      _passwordController.text, _confirmPasswordController.text);

  bool get _isFormValid => _logic.isFormValid(
        name: _fullNameController.text,
        email: _emailController.text,
        rawPhone: _phoneController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        isTermsAgreed: _isTermsAgreed,
      );

  String _getFormattedFullPhone() {
    return _logic.formatFullPhone(_selectedCountry.dialCode, _phoneController.text);
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

  Future<void> _submitRegistrationForm() async {
    if (!_isFormValid) {
      setState(() {
        _hasError = true;
        _errorMessage = _logic.getValidationErrorMessage(
          isTermsAgreed: _isTermsAgreed,
          name: _fullNameController.text,
          rawPhone: _phoneController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
      });
      return;
    }

    final fullPhone = _getFormattedFullPhone();

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await _logic.validatePhoneAndEmailUniqueness(
        fullPhone: fullPhone,
        email: _emailController.text,
      );
      await _dispatchOtp(isResend: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _dispatchOtp({bool isResend = false}) async {
    final fullPhone = _getFormattedFullPhone();

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final waResult = await _logic.sendWhatsAppOtp(fullPhone);

      if (waResult.success) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _otpDeliveryMode = OtpDeliveryMode.whatsapp;
          _currentStep = RegisterStep.verifyOtp;
          _hasOtpError = false;
        });
        _startCountdown();
        _otpFocusNodes[0].requestFocus();

        if (waResult.simulated && waResult.simulatedCode != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Kode OTP Simulasi: [${waResult.simulatedCode}] (Scan QR di http://localhost:3000/qr untuk WA asli)',
                style: GoogleFonts.roboto(fontSize: 12, color: Colors.white),
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 8),
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      showFallbackSmsDialog();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showFallbackSmsDialog();
    }
  }

  Future<void> _dispatchSmsOtp() async {
    final fullPhone = _getFormattedFullPhone();

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await _logic.sendSmsOtp(
        fullPhone: fullPhone,
        resendToken: _resendToken,
        onCodeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _otpDeliveryMode = OtpDeliveryMode.sms;
            _verificationId = verificationId;
            _resendToken = resendToken;
            _currentStep = RegisterStep.verifyOtp;
            _hasOtpError = false;
          });
          _startCountdown();
          _otpFocusNodes[0].requestFocus();
        },
        onVerificationFailed: (error) {
          if (!mounted) return;
          final friendlyMsg = _logic.getHumanReadablePhoneAuthError(error);
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = friendlyMsg;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'SMS Gagal: [$friendlyMsg]',
                style: GoogleFonts.roboto(fontSize: 12, color: Colors.white),
              ),
              backgroundColor: const Color(0xFFE83535),
              duration: const Duration(seconds: 5),
            ),
          );
        },
        onVerificationCompleted: (credential) async {
          if (!mounted) return;
          await _completeRegistration();
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Gagal memproses verifikasi SMS: ${e.toString()}';
      });
    }
  }

  Future<void> _verifyOtpAndSubmit() async {
    final otpCode = _otpControllers.map((c) => c.text).join();

    if (otpCode.length < 6) {
      setState(() {
        _hasOtpError = true;
        _otpErrorMessage = 'Masukkan 6 digit kode OTP verifikasi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasOtpError = false;
    });

    try {
      if (_otpDeliveryMode == OtpDeliveryMode.whatsapp) {
        final fullPhone = _getFormattedFullPhone();
        final isValid = await _logic.verifyWhatsAppOtp(fullPhone, otpCode);
        if (!isValid) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _hasOtpError = true;
            _otpErrorMessage = 'Kode OTP WhatsApp salah atau telah kedaluwarsa.';
          });
          return;
        }
      } else {
        if (_verificationId != null) {
          await _logic.verifySmsOtp(_verificationId!, otpCode);
        }
      }

      await _completeRegistration();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasOtpError = true;
        if (e.code == 'invalid-verification-code') {
          _otpErrorMessage =
              'Kode OTP yang Anda masukkan salah. Periksa kembali.';
        } else if (e.code == 'session-expired') {
          _otpErrorMessage =
              'Kode OTP telah kedaluwarsa. Silakan kirim ulang kode.';
        } else {
          _otpErrorMessage = e.message ?? 'Verifikasi kode gagal.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasOtpError = true;
        _otpErrorMessage = 'Gagal memverifikasi: ${e.toString()}';
      });
    }
  }

  Future<void> _completeRegistration() async {
    try {
      await _logic.completeRegistration(
        name: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        fullPhone: _getFormattedFullPhone(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasOtpError = false;
      });

      RegisterSuccessDialog.show(
        context,
        formattedPhone: _getFormattedFullPhone(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasOtpError = true;
        _otpErrorMessage = 'Gagal menyimpan profil: ${e.toString()}';
      });
    }
  }

  void _showCountryPicker() {
    CountryPickerSheet.show(
      context,
      selectedCountry: _selectedCountry,
      onCountrySelected: (item) {
        setState(() {
          _selectedCountry = item;
        });
      },
    );
  }

  void showFallbackSmsDialog() {
    FallbackSmsDialog.show(
      context,
      onSendSms: () => _dispatchSmsOtp(),
    );
  }

  void _showTermsAndConditions() {
    TermsBottomSheet.show(
      context,
      onAgree: () {
        setState(() {
          _isTermsAgreed = true;
        });
      },
    );
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final credential = await _logic.signInWithGoogle();
      if (!mounted) return;

      if (credential != null && credential.user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Gagal mendaftar dengan Google. Silakan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 22.0),
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
                      child: _currentStep == RegisterStep.form
                          ? RegisterFormView(
                              fullNameController: _fullNameController,
                              emailController: _emailController,
                              phoneController: _phoneController,
                              passwordController: _passwordController,
                              confirmPasswordController: _confirmPasswordController,
                              selectedCountry: _selectedCountry,
                              onCountryTap: _showCountryPicker,
                              obscurePassword: _obscurePassword,
                              onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                              obscureConfirmPassword: _obscureConfirmPassword,
                              onToggleConfirmPassword: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              isNameValid: _isNameValid,
                              isEmailValid: _isEmailValid,
                              isPhoneValid: _isPhoneValid,
                              isPasswordValid: _isPasswordValid,
                              isConfirmPasswordValid: _isConfirmPasswordValid,
                              isTermsAgreed: _isTermsAgreed,
                              onTermsChanged: (val) => setState(() => _isTermsAgreed = val ?? false),
                              onTapTerms: _showTermsAndConditions,
                              isFormValid: _isFormValid,
                              isLoading: _isLoading,
                              onSubmit: _submitRegistrationForm,
                              hasError: _hasError,
                              errorMessage: _errorMessage,
                              onGoogleSignUp: _handleGoogleSignUp,
                              onTapLogin: () => Navigator.of(context).pop(),
                            )
                          : RegisterOtpView(
                              otpDeliveryMode: _otpDeliveryMode,
                              formattedPhone: _getFormattedFullPhone(),
                              hasOtpError: _hasOtpError,
                              otpErrorMessage: _otpErrorMessage,
                              otpControllers: _otpControllers,
                              otpFocusNodes: _otpFocusNodes,
                              resendCountdown: _resendCountdown,
                              formattedCountdown: _logic.formatCountdown(_resendCountdown),
                              isLoading: _isLoading,
                              onResendOtp: () => _dispatchOtp(isResend: true),
                              onFallbackSms: showFallbackSmsDialog,
                              onVerify: _verifyOtpAndSubmit,
                              onBackToForm: () {
                                setState(() {
                                  _currentStep = RegisterStep.form;
                                  _hasOtpError = false;
                                });
                              },
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
}
