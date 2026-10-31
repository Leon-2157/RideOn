import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/country_code.dart';
import '../../../auth/presentation/modules/register/country_picker_sheet.dart';
import '../widgets/sub_header_widget.dart';
import '../modules/nomor_wa/nomor_wa_form_card.dart';
import '../modules/nomor_wa/nomor_wa_logic.dart';
import '../modules/nomor_wa/nomor_wa_otp_card.dart';

export '../modules/nomor_wa/nomor_wa_form_card.dart';
export '../modules/nomor_wa/nomor_wa_logic.dart';
export '../modules/nomor_wa/nomor_wa_otp_card.dart';

class NomorWaScreen extends StatefulWidget {
  final String currentPhone;

  const NomorWaScreen({super.key, required this.currentPhone});

  @override
  State<NomorWaScreen> createState() => _NomorWaScreenState();
}

class _NomorWaScreenState extends State<NomorWaScreen> {
  final _passwordController = TextEditingController();
  final _oldPhoneController = TextEditingController();
  final _newPhoneController = TextEditingController();

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  final NomorWaLogic _logic = NomorWaLogic();

  CountryCode _selectedOldCountry = supportedCountries[0];
  CountryCode _selectedNewCountry = supportedCountries[0];

  bool _obscurePassword = true;
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  bool get _hasCurrentPhone =>
      widget.currentPhone.trim().isNotEmpty &&
      widget.currentPhone.trim() != 'Belum ditambahkan' &&
      widget.currentPhone.trim() != '0812-3456-7890';

  int _countdownSeconds = 60;
  Timer? _countdownTimer;
  String _targetNormalizedPhone = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _oldPhoneController.dispose();
    _newPhoneController.dispose();
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

  void _showCountryPicker({required bool isForOld}) {
    CountryPickerSheet.show(
      context,
      selectedCountry: isForOld ? _selectedOldCountry : _selectedNewCountry,
      title: 'Pilih Negara & Kode Nomor',
      subtitle: isForOld
          ? 'Pilih negara untuk Nomor WhatsApp Lama'
          : 'Pilih negara untuk Nomor WhatsApp Baru',
      onCountrySelected: (country) {
        setState(() {
          if (isForOld) {
            _selectedOldCountry = country;
          } else {
            _selectedNewCountry = country;
          }
        });
      },
    );
  }

  Future<void> _handleSendOtp() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final fullNewPhone = await _logic.validateAndSendOtp(
        password: _passwordController.text.trim(),
        rawOldPhone: _oldPhoneController.text.trim(),
        rawNewPhone: _newPhoneController.text.trim(),
        oldDialCode: _selectedOldCountry.dialCode,
        newDialCode: _selectedNewCountry.dialCode,
        currentPhone: widget.currentPhone,
        hasCurrentPhone: _hasCurrentPhone,
      );

      _targetNormalizedPhone = fullNewPhone;
      final waResult = await _logic.sendOtp(_targetNormalizedPhone);

      if (!waResult.success) {
        throw waResult.error ?? 'Gagal mengirimkan kode OTP ke WhatsApp.';
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

      if (waResult.simulated && waResult.simulatedCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kode OTP Simulasi: [${waResult.simulatedCode}]'),
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
      _errorMessage = null;
    });

    try {
      final waResult = await _logic.sendOtp(_targetNormalizedPhone);
      if (!waResult.success) {
        throw waResult.error ?? 'Gagal mengirim ulang kode OTP.';
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      _startCountdown();

      if (waResult.simulated && waResult.simulatedCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kode OTP Simulasi: [${waResult.simulatedCode}]'),
            backgroundColor: const Color(0xFF6B48FC),
            duration: const Duration(seconds: 8),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode OTP baru telah dikirimkan via WhatsApp!'),
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
      _errorMessage = null;
    });

    try {
      await _logic.verifyOtpAndSave(
        targetPhone: _targetNormalizedPhone,
        code: code,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nomor WhatsApp berhasil diperbarui ke $_targetNormalizedPhone!'),
          backgroundColor: const Color(0xFF6B48FC),
        ),
      );

      Navigator.of(context).pop(_targetNormalizedPhone);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
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
          buildSubHeader(context, 'Nomor WhatsApp'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7BCFE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isOtpSent
                          ? 'Kode OTP telah dikirimkan ke nomor WhatsApp $_targetNormalizedPhone. Silakan masukkan 6 digit kode untuk verifikasi.'
                          : _hasCurrentPhone
                              ? 'Nomor WhatsApp terdaftar saat ini: ${widget.currentPhone}\n'
                                  'Untuk menggantinya, konfirmasi kata sandi akun, nomor lama, dan masukkan nomor baru Anda.'
                              : 'Nomor WhatsApp belum terdaftar.\n'
                                  'Masukkan kata sandi akun dan nomor baru Anda untuk menghubungkan nomor WhatsApp.',
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        color: const Color(0xFF17152B),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (_hasError && _errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 18, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.roboto(
                                fontSize: 11.5,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (!_isOtpSent)
                    NomorWaFormCard(
                      passwordController: _passwordController,
                      oldPhoneController: _oldPhoneController,
                      newPhoneController: _newPhoneController,
                      selectedOldCountry: _selectedOldCountry,
                      selectedNewCountry: _selectedNewCountry,
                      obscurePassword: _obscurePassword,
                      onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                      onSelectOldCountry: () => _showCountryPicker(isForOld: true),
                      onSelectNewCountry: () => _showCountryPicker(isForOld: false),
                      hasCurrentPhone: _hasCurrentPhone,
                      isLoading: _isLoading,
                      onSubmit: _handleSendOtp,
                    )
                  else
                    NomorWaOtpCard(
                      targetNormalizedPhone: _targetNormalizedPhone,
                      otpControllers: _otpControllers,
                      otpFocusNodes: _otpFocusNodes,
                      countdownSeconds: _countdownSeconds,
                      isLoading: _isLoading,
                      onResend: _handleResendOtp,
                      onVerifyAndSave: _handleVerifyAndSave,
                      onResetToForm: () {
                        setState(() {
                          _isOtpSent = false;
                          _hasError = false;
                          _errorMessage = null;
                          for (final c in _otpControllers) {
                            c.clear();
                          }
                        });
                      },
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
