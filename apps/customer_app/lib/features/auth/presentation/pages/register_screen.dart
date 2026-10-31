import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../main/presentation/pages/main_screen.dart';
import '../../data/auth_service.dart';
import '../../data/wa_gateway_service.dart';
import 'login_screen.dart';

enum RegisterStep {
  form,      // Form 5 field (Nama, Email, No WA + Flag, Kata Sandi, Ulangi Sandi)
  verifyOtp, // Layar 6 digit OTP (Figma: verif otp daftar.png)
}

/// Model Kode Negara
class CountryCode {
  final String name;
  final String flag;
  final String dialCode;

  const CountryCode({
    required this.name,
    required this.flag,
    required this.dialCode,
  });
}

const List<CountryCode> _supportedCountries = [
  CountryCode(name: 'Indonesia', flag: '🇮🇩', dialCode: '+62'),
  CountryCode(name: 'Malaysia', flag: '🇲🇾', dialCode: '+60'),
  CountryCode(name: 'Singapura', flag: '🇸🇬', dialCode: '+65'),
  CountryCode(name: 'Filipina', flag: '🇵🇭', dialCode: '+63'),
  CountryCode(name: 'Thailand', flag: '🇹🇭', dialCode: '+66'),
  CountryCode(name: 'Vietnam', flag: '🇻🇳', dialCode: '+84'),
  CountryCode(name: 'Arab Saudi', flag: '🇸🇦', dialCode: '+966'),
  CountryCode(name: 'Amerika Serikat', flag: '🇺🇸', dialCode: '+1'),
  CountryCode(name: 'Inggris', flag: '🇬🇧', dialCode: '+44'),
  CountryCode(name: 'Australia', flag: '🇦🇺', dialCode: '+61'),
  CountryCode(name: 'Jepang', flag: '🇯🇵', dialCode: '+81'),
  CountryCode(name: 'Korea Selatan', flag: '🇰🇷', dialCode: '+82'),
];

/// Formatter Khusus Nomor Telepon:
/// 1. Mencegah angka 0 di awal nomor
/// 2. Memberi spasi otomatis antar kelompok angka (contoh: 853 2344 1080)
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Cegah angka 0 di awal nomor
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // Batasi panjang maksimal 13 digit
    if (digits.length > 13) {
      digits = digits.substring(0, 13);
    }

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 7 || i == 11) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }

    final String formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

enum OtpDeliveryMode {
  whatsapp,
  sms,
}

/// Screen Pendaftaran Akun Customer RideOn
/// Mengimplementasikan 5 Form Field + Live Real-time Validation (Merah/Hijau)
/// + Auto-Spacing Phone Formatter + Disabled Button State + Dual OTP (WA & SMS Fallback)
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

  // Controllers Form (5 Fields)
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Country Code Picker
  CountryCode _selectedCountry = _supportedCountries[0]; // Default: 🇮🇩 +62

  // Controllers 6-Digit OTP
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  // Form State
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isTermsAgreed = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // OTP State
  bool _hasOtpError = false;
  String _otpErrorMessage = '';
  int _resendCountdown = 60;
  Timer? _countdownTimer;
  String? _verificationId;
  int? _resendToken;

  late final AuthService _authService;
  late final WaGatewayService _waGatewayService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _waGatewayService = widget.waGatewayService ?? WaGatewayService();

    // Listener real-time agar UI validasi (border merah/hijau & tombol disable/enable)
    // bereaksi langsung saat pengguna mengetik
    _fullNameController.addListener(_onFormFieldChanged);
    _emailController.addListener(_onFormFieldChanged);
    _phoneController.addListener(_onFormFieldChanged);
    _passwordController.addListener(_onFormFieldChanged);
    _confirmPasswordController.addListener(_onFormFieldChanged);
  }

  void _onFormFieldChanged() {
    if (mounted) {
      setState(() {});
    }
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

  // ===========================================================================
  // Getter Status Validasi Real-Time Per Field
  // ===========================================================================
  bool get _isNameValid => _fullNameController.text.trim().length >= 3;

  bool get _isEmailValid {
    final text = _emailController.text.trim();
    if (text.isEmpty) return true; // Opsional
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text);
  }

  bool get _isPhoneValid =>
      _phoneController.text.replaceAll(' ', '').length >= 9;

  bool get _isPasswordValid => _passwordController.text.length >= 8;

  bool get _isConfirmPasswordValid =>
      _confirmPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text == _passwordController.text;

  /// Seluruh form valid jika semua kondisi terpenuhi + Syarat Ketentuan dicentang
  bool get _isFormValid =>
      _isNameValid &&
      _isEmailValid &&
      _isPhoneValid &&
      _isPasswordValid &&
      _isConfirmPasswordValid &&
      _isTermsAgreed;

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatCountdown() {
    final minutes = (_resendCountdown ~/ 60).toString().padLeft(2, '0');
    final seconds = (_resendCountdown % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Helper untuk mendapatkan nomor telepon lengkap dengan format internasional
  String _getFormattedFullPhone() {
    String cleanDigits =
        _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return '${_selectedCountry.dialCode}$cleanDigits';
  }

  // ===========================================================================
  // Step 1: Submit Form & Kirim OTP
  // ===========================================================================
  Future<void> _submitRegistrationForm() async {
    if (!_isFormValid) {
      setState(() {
        _hasError = true;
        if (!_isTermsAgreed) {
          _errorMessage =
              'Anda harus menyetujui Syarat & Ketentuan RideOn untuk mendaftar.';
        } else if (!_isNameValid) {
          _errorMessage = 'Nama lengkap minimal 3 karakter.';
        } else if (!_isPhoneValid) {
          _errorMessage = 'Nomor WhatsApp minimal 9 digit.';
        } else if (!_isPasswordValid) {
          _errorMessage = 'Kata sandi minimal 8 karakter.';
        } else if (!_isConfirmPasswordValid) {
          _errorMessage =
              'Konfirmasi kata sandi tidak cocok. Mohon periksa kembali.';
        } else {
          _errorMessage = 'Mohon periksa kembali data pendaftaran Anda.';
        }
      });
      return;
    }

    final fullPhone = _getFormattedFullPhone();

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // 1. Cek apakah nomor sudah terdaftar
      final phoneInUse = await _authService.isPhoneRegistered(fullPhone);
      if (phoneInUse) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              'Nomor WhatsApp ini sudah terdaftar. Silakan masuk.';
        });
        return;
      }

      // 2. Cek apakah email (jika diisi) sudah terdaftar
      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
        final emailInUse = await _authService.isEmailRegistered(email);
        if (emailInUse) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage =
                'Alamat email ini sudah terdaftar. Silakan gunakan email lain.';
          });
          return;
        }
      }

      // 3. Kirim OTP via Firebase Phone Auth
      await _dispatchOtp(isResend: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Gagal memproses pendaftaran: ${e.toString()}';
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
      // 1. Coba kirimkan kode OTP via WhatsApp Gateway terlebih dahulu
      final waResult = await _waGatewayService.sendOtp(fullPhone);

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

      // 2. Jika WhatsApp Gateway offline / gagal, munculkan dialog fallback SMS
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showFallbackSmsDialog();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showFallbackSmsDialog();
    }
  }

  /// Dispatch OTP via Firebase Phone Auth (SMS Fallback)
  Future<void> _dispatchSmsOtp() async {
    final fullPhone = _getFormattedFullPhone();

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await _authService.sendPhoneOtp(
        phoneNumber: fullPhone,
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
          debugPrint('Firebase PhoneAuth onVerificationFailed: [${error.code}] ${error.message}');
          final friendlyMsg = _getHumanReadablePhoneAuthError(error);
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

  /// Konversi kode error Firebase Phone Auth menjadi pesan instruktif
  String _getHumanReadablePhoneAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'missing-client-identifier':
      case 'app-not-authorized':
        return 'Perangkat ditolak Firebase (SHA-256 belum terdaftar di Firebase Console). Silakan daftarkan SHA-256 atau gunakan Nomor Pengujian di Console.';
      case 'operation-not-allowed':
        if (error.message?.contains('region') == true) {
          return 'Wilayah SMS belum diizinkan. Buka Firebase Console > Authentication > Settings > SMS Region Policy, lalu tambahkan "Indonesia (+62)".';
        }
        return 'Provider Phone Auth belum aktif atau wilayah SMS dibatasi di Firebase Console.';
      case 'quota-exceeded':
        return 'Batas kuota SMS Firebase harian tercapai. Daftarkan nomor uji coba di Firebase Console untuk pengujian.';
      case 'invalid-phone-number':
        return 'Format nomor telepon tidak valid. Pastikan format internasional benar.';
      case 'unknown':
        if (error.message?.contains('BILLING_NOT_ENABLED') == true) {
          return 'Pengiriman SMS nyata memerlukan Firebase Blaze Plan (Billing). Daftarkan nomor di "Phone numbers for testing" di Firebase Console untuk pengujian gratis tanpa kartu kredit.';
        }
        return error.message ?? 'Terjadi kesalahan sistem internal.';
      default:
        return '[${error.code}] ${error.message ?? 'Verifikasi SMS gagal.'}';
    }
  }

  // ===========================================================================
  // Step 2: Verifikasi OTP & Selesaikan Akun
  // ===========================================================================
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
        final isValid = await _waGatewayService.verifyOtp(fullPhone, otpCode);
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
          await _authService.verifyPhoneOtpCode(
            verificationId: _verificationId!,
            smsCode: otpCode,
          );
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
    final name = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final fullPhone = _getFormattedFullPhone();
    final password = _passwordController.text;

    try {
      await _authService.registerCustomerAccount(
        fullName: name,
        email: email.isNotEmpty ? email : null,
        phoneNumber: fullPhone,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasOtpError = false;
      });

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasOtpError = true;
        _otpErrorMessage = 'Gagal menyimpan profil: ${e.toString()}';
      });
    }
  }

  // ===========================================================================
  // Modal Bottom Sheet: Country Code Selector
  // ===========================================================================
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Color(0xFFF7F6FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Negara & Kode Nomor',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Format kode telepon internasional',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: AppColors.dark.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.dark),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2DCFE)),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _supportedCountries.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Color(0xFFEEEBFE)),
                  itemBuilder: (context, index) {
                    final item = _supportedCountries[index];
                    final isSelected = item.dialCode == _selectedCountry.dialCode;

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : null,
                      leading: Text(
                        item.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        item.name,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.dark,
                        ),
                      ),
                      trailing: Text(
                        item.dialCode,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.dark,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCountry = item;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // Dialog Fallback SMS (Figma: dialog fallback sms.png)
  // ===========================================================================
  void showFallbackSmsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EFFE),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.sms_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Layanan WhatsApp Pemeliharaan',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pengiriman kode via WhatsApp sedang tidak tersedia.\nApakah Anda ingin mengirimkan kode verifikasi melalui SMS?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: AppColors.dark.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        key: const Key('btn_fallback_kirim_sms'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _dispatchSmsOtp();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'KIRIM KODE VIA SMS',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
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

  // ===========================================================================
  // Dialog Berhasil Daftar (Figma: berhasil daftar.png)
  // ===========================================================================
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
                    Text(
                      'Akun berhasil dibuat!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Akun Anda telah berhasil dibuat.\nSilakan masuk dengan akun yang telah Anda daftarkan.',
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
                        key: const Key('btn_masuk_sekarang_success'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(
                                initialIdentifier: _getFormattedFullPhone(),
                              ),
                            ),
                          );
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

  // ===========================================================================
  // Bottom Sheet Syarat & Ketentuan (Figma: syarat dan ketentuan.png)
  // ===========================================================================
  void _showTermsAndConditions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTermsSheet(),
    );
  }

  Widget _buildTermsSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFE2DCFE),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Syarat & Ketentuan RideOn',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ketentuan umum penggunaan layanan transportasi',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: AppColors.dark.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('close_terms_sheet'),
                      icon: const Icon(Icons.close_rounded, color: AppColors.dark),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFC6BCFF)),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    Text(
                      'Selamat datang di RideOn. Dengan mendaftar dan menggunakan platform ini, Anda menyatakan tunduk dan terikat pada syarat dan ketentuan berikut sesuai hukum yang berlaku di Republik Indonesia.',
                      style: GoogleFonts.roboto(fontSize: 12, height: 1.5, color: AppColors.dark),
                    ),
                    _buildTermsSection(
                      '1. Ketentuan Umum & Definisi',
                      [
                        'RideOn adalah platform perantara yang mempertemukan pihak yang menyediakan layanan transportasi (Mitra Pengemudi) dengan pihak yang membutuhkan layanan perjalanan (Penumpang/Customer).',
                        'RideOn tidak memiliki, menguasai, atau mengelola armada kendaraan yang digunakan oleh Mitra Pengemudi di dalam platform ini.',
                        'Pengguna wajib berusia minimal 17 tahun dan/atau memiliki identitas resmi (KTP/SIM/Paspor) yang sah menurut hukum Republik Indonesia.',
                      ],
                    ),
                    _buildTermsSection(
                      '2. Tanggung Jawab Customer',
                      [
                        'Customer wajib memberikan informasi titik penjemputan dan titik tujuan yang asli dan valid saat melakukan transaksi pemesanan perjalanan.',
                        'Customer dilarang keras membawa barang terlarang, ilegal, atau berbahaya selama perjalanan berlangsung.',
                        'Customer wajib mematuhi peraturan lalu lintas, termasuk menggunakan helm pelindung (untuk layanan ojek motor).',
                      ],
                    ),
                    _buildTermsSection(
                      '3. Tanggung Jawab Mitra Driver',
                      [
                        'Mitra Pengemudi bertanggung jawab penuh atas keselamatan penumpang dan kelayakan jalan kendaraan.',
                        'Mitra Pengemudi berhak menolak pesanan jika Customer dinilai mencurigakan atau membawa muatan berlebih.',
                      ],
                    ),
                    _buildTermsSection(
                      '4. Batasan Tanggung Jawab',
                      [
                        'RideOn terlepas dari segala tuntutan hukum atas kelalaian individu pengguna atau pengemudi di luar SOP resmi.',
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    key: const Key('btn_agree_terms'),
                    onPressed: () {
                      setState(() {
                        _isTermsAgreed = true;
                      });
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'SAYA MENGERTI & SETUJU',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTermsSection(String heading, List<String> points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      point,
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        height: 1.4,
                        color: AppColors.dark.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Build Method Utama
  // ===========================================================================
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
                          ? _buildRegistrationForm()
                          : _buildOtpVerificationView(),
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

  // ===========================================================================
  // View 1: Form Pendaftaran 5 Field (Dengan Picker Bendera & Ulangi Sandi)
  // ===========================================================================
  Widget _buildRegistrationForm() {
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
        if (_hasError) ...[
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
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFE83535), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage,
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
        _buildInputField(
          controller: _fullNameController,
          hintText: 'Nama Lengkap *',
          prefixIcon: Icons.person_rounded,
          isValid: _isNameValid,
          keyName: 'input_register_name',
        ),
        const SizedBox(height: 12),

        // Field 2: Alamat Email (Opsional)
        _buildInputField(
          controller: _emailController,
          hintText: 'Alamat Email (Opsional)',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          isValid: _isEmailValid,
          keyName: 'input_register_email',
        ),
        const SizedBox(height: 12),

        // Field 3: No. WhatsApp Aktif * (Dengan Picker Bendera & Auto Spacing)
        _buildPhoneFieldWithCountryPicker(),
        const SizedBox(height: 12),

        // Field 4: Kata sandi (Min. 8 karakter) *
        _buildInputField(
          controller: _passwordController,
          hintText: 'Kata sandi (Min. 8 karakter) *',
          prefixIcon: Icons.lock_rounded,
          obscureText: _obscurePassword,
          isValid: _isPasswordValid,
          keyName: 'input_register_password',
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 17,
              color: AppColors.dark,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Field 5: Ulangi Kata Sandi * (Validasi Kecocokan Kata Sandi)
        _buildInputField(
          controller: _confirmPasswordController,
          hintText: 'Ulangi Kata Sandi *',
          prefixIcon: Icons.security_rounded,
          obscureText: _obscureConfirmPassword,
          isValid: _isConfirmPasswordValid,
          keyName: 'input_register_confirm_password',
          suffixIcon: GestureDetector(
            onTap: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
            child: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 17,
              color: AppColors.dark,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Checkbox: Syarat & Ketentuan (Figma ceklis.png)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
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
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  key: const Key('checkbox_terms'),
                  value: _isTermsAgreed,
                  activeColor: AppColors.dark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _isTermsAgreed = val ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  key: const Key('link_syarat_ketentuan'),
                  onTap: _showTermsAndConditions,
                  child: RichText(
                    text: TextSpan(
                      text: 'Saya menyetujui ',
                      style: GoogleFonts.roboto(
                        fontSize: 10.5,
                        color: AppColors.dark,
                      ),
                      children: [
                        TextSpan(
                          text: 'Syarat & Ketentuan',
                          style: GoogleFonts.roboto(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            color: AppColors.dark,
                          ),
                        ),
                        const TextSpan(text: ' RideOn.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tombol: BUAT AKUN (Warna Abu & Disabled jika belum valid semua)
        SizedBox(
          height: 42,
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('btn_buat_akun'),
            onPressed:
                _isFormValid && !_isLoading ? _submitRegistrationForm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFormValid
                  ? AppColors.dark
                  : const Color(0xFF9E9EAF).withValues(alpha: 0.40),
              foregroundColor: _isFormValid
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.60),
              disabledBackgroundColor:
                  const Color(0xFF9E9EAF).withValues(alpha: 0.40),
              disabledForegroundColor:
                  Colors.white.withValues(alpha: 0.60),
              elevation: _isFormValid ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13.0),
              ),
              padding: EdgeInsets.zero,
            ),
            child: _isLoading
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
        ),
        const SizedBox(height: 16),

        // Footer: Sudah punya akun? Masuk di sini
        GestureDetector(
          key: const Key('link_ke_halaman_masuk'),
          onTap: () => Navigator.of(context).pop(),
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
        ),
      ],
    );
  }

  // ===========================================================================
  // Field Phone Khusus dengan Country Code, Flag Picker, & Auto Spacing Formatter
  // ===========================================================================
  Widget _buildPhoneFieldWithCountryPicker() {
    Color phoneBorderColor;
    double phoneBorderWidth;

    if (_phoneController.text.trim().isEmpty) {
      phoneBorderColor = Colors.white.withValues(alpha: 0.35);
      phoneBorderWidth = 0.8;
    } else if (_isPhoneValid) {
      phoneBorderColor = const Color(0xFF00B894);
      phoneBorderWidth = 1.2;
    } else {
      phoneBorderColor = const Color(0xFFE83535);
      phoneBorderWidth = 1.2;
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.only(left: 6.0, right: 14.0),
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
        border: Border.all(
          color: phoneBorderColor,
          width: phoneBorderWidth,
        ),
      ),
      child: Row(
        children: [
          // Tombol Picker Bendera & Kode Negara
          InkWell(
            key: const Key('btn_country_picker'),
            onTap: _showCountryPicker,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCountry.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedCountry.dialCode,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: AppColors.dark,
                  ),
                ],
              ),
            ),
          ),

          // Garis Pembatas Vertikal
          Container(
            height: 20,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: AppColors.dark.withValues(alpha: 0.25),
          ),

          // Input Nomor WhatsApp (Mencegah angka 0 dan spasi otomatis)
          Expanded(
            child: TextField(
              key: const Key('input_register_phone'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                PhoneNumberFormatter(),
              ],
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: AppColors.dark,
              ),
              decoration: InputDecoration(
                hintText: '812 3456 7890',
                hintStyle: GoogleFonts.roboto(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w400,
                  color: AppColors.dark.withValues(alpha: 0.65),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // View 2: Verifikasi OTP 6 Digit (Figma: verif otp daftar.png)
  // ===========================================================================
  Widget _buildOtpVerificationView() {
    final fullPhone = _getFormattedFullPhone();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _otpDeliveryMode == OtpDeliveryMode.whatsapp
              ? 'Verifikasi Nomor WhatsApp'
              : 'Verifikasi Kode OTP SMS',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _otpDeliveryMode == OtpDeliveryMode.whatsapp
              ? 'Masukkan 6 digit kode yang kami kirimkan ke nomor WhatsApp Anda $fullPhone'
              : 'Masukkan 6 digit kode yang dikirimkan melalui SMS ke nomor $fullPhone',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.dark.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        // Error Banner OTP (Figma: verif salah.png)
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
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFE83535), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _otpErrorMessage,
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
          const SizedBox(height: 14),
        ],

        // 6 Kotak PIN OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) => _buildOtpBox(index)),
        ),
        const SizedBox(height: 18),

        // Countdown Timer & Resend
        if (_resendCountdown > 0)
          Text(
            'Kirim ulang kode dalam (${_formatCountdown()})',
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.dark.withValues(alpha: 0.7),
            ),
          )
        else
          GestureDetector(
            key: const Key('btn_resend_otp'),
            onTap: _isLoading ? null : () => _dispatchOtp(isResend: true),
            child: Text(
              'Kirim Ulang Kode',
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Fallback Link / Catatan
        if (_otpDeliveryMode == OtpDeliveryMode.whatsapp)
          GestureDetector(
            key: const Key('link_fallback_sms_in_otp'),
            onTap: () => showFallbackSmsDialog(),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: 'Tidak menerima kode di WhatsApp? ',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: AppColors.dark.withValues(alpha: 0.8),
                ),
                children: [
                  TextSpan(
                    text: 'Kirim via SMS',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Text(
            'Pastikan nomor Anda aktif untuk menerima SMS.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 10.5,
              color: AppColors.dark.withValues(alpha: 0.65),
            ),
          ),
        const SizedBox(height: 20),

        // Tombol VERIFIKASI
        SizedBox(
          height: 42,
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('btn_verifikasi_otp'),
            onPressed: _isLoading ? null : _verifyOtpAndSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13.0),
              ),
              padding: EdgeInsets.zero,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'VERIFIKASI',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 14),

        // Link Footer: Ubah Nomor Telepon
        GestureDetector(
          key: const Key('btn_back_to_form'),
          onTap: () {
            setState(() {
              _currentStep = RegisterStep.form;
              _hasOtpError = false;
            });
          },
          child: Text(
            'Ubah Nomor Telepon',
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.dark.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Komponen Input Kotak OTP
  // ===========================================================================
  Widget _buildOtpBox(int index) {
    return Container(
      width: 44,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
          color: _hasOtpError
              ? const Color(0xFFE83535)
              : Colors.white.withValues(alpha: 0.5),
          width: _hasOtpError ? 1.5 : 1.0,
        ),
      ),
      child: Center(
        child: TextField(
          key: Key('otp_box_$index'),
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < 5) {
                _otpFocusNodes[index + 1].requestFocus();
              } else {
                _otpFocusNodes[index].unfocus();
                _verifyOtpAndSubmit();
              }
            } else if (value.isEmpty && index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // Reusable Widgets: Input Field, Google Button, Divider
  // ===========================================================================
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required bool isValid,
    String? keyName,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    // Tentukan warna border:
    // Jika belum diisi (kosong) -> netral abu-abu/putih frosted sesuai desain asli Figma
    // Jika sudah diisi dan valid -> hijau emerald
    // Jika sudah diisi tapi masih salah -> merah
    Color borderColor;
    double borderWidth;

    if (controller.text.trim().isEmpty) {
      borderColor = Colors.white.withValues(alpha: 0.35);
      borderWidth = 0.8;
    } else if (isValid) {
      borderColor = const Color(0xFF00B894);
      borderWidth = 1.2;
    } else {
      borderColor = const Color(0xFFE83535);
      borderWidth = 1.2;
    }

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
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Center(
        child: Row(
          children: [
            Icon(
              prefixIcon,
              size: 16.0,
              color: AppColors.dark,
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: TextField(
                key: keyName != null ? Key(keyName) : null,
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                style: GoogleFonts.roboto(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.dark,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.roboto(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.dark.withValues(alpha: 0.65),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            ?suffixIcon,
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      height: 42,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 3),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: ElevatedButton(
        key: const Key('btn_google_signup'),
        onPressed: _isLoading ? null : _handleGoogleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.dark,
          elevation: 0,
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
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Lanjutkan Dengan Google',
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final credential = await _authService.signInWithGoogle();
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.7,
            color: AppColors.dark.withValues(alpha: 0.25),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            'ATAU',
            style: GoogleFonts.roboto(
              fontSize: 10.0,
              fontWeight: FontWeight.w600,
              color: AppColors.dark.withValues(alpha: 0.65),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.7,
            color: AppColors.dark.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}
