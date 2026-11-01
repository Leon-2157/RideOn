import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/data/wa_gateway_service.dart';
import '../widgets/country_code_selector.dart';
import '../widgets/sub_header_widget.dart';

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

  final AuthService _authService = AuthService();
  final WaGatewayService _waGatewayService = WaGatewayService();

  // State Country Picker
  CountryCode _selectedOldCountry = supportedCountries[0]; // Default: 🇮🇩 +62
  CountryCode _selectedNewCountry = supportedCountries[0]; // Default: 🇮🇩 +62

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
    setState(() {
      _countdownSeconds = 60;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        if (mounted) {
          setState(() {
            _countdownSeconds--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _showCountryPicker({required bool isForOld}) {
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
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isForOld
                                ? 'Pilih negara untuk Nomor WhatsApp Lama'
                                : 'Pilih negara untuk Nomor WhatsApp Baru',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: const Color(0xFF17152B).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF17152B)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2DCFE)),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: supportedCountries.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Color(0xFFEEEBFE)),
                  itemBuilder: (context, index) {
                    final item = supportedCountries[index];
                    final currentSelected = isForOld ? _selectedOldCountry : _selectedNewCountry;
                    final isSelected = item.dialCode == currentSelected.dialCode;

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: isSelected
                          ? const Color(0xFF6B48FC).withValues(alpha: 0.12)
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
                          color: const Color(0xFF17152B),
                        ),
                      ),
                      trailing: Text(
                        item.dialCode,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? const Color(0xFF6B48FC) : const Color(0xFF17152B),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if (isForOld) {
                            _selectedOldCountry = item;
                          } else {
                            _selectedNewCountry = item;
                          }
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

  Future<void> _handleSendOtp() async {
    final password = _passwordController.text.trim();
    final rawOldPhone = _oldPhoneController.text.trim();
    final rawNewPhone = _newPhoneController.text.trim();

    if (password.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Masukkan kata sandi akun untuk konfirmasi keamanan.';
      });
      return;
    }

    // 1. Validasi kecocokan Nomor Lama jika akun sudah memiliki nomor sebelumnya
    if (_hasCurrentPhone) {
      if (rawOldPhone.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Masukkan nomor WhatsApp lama akun Anda.';
        });
        return;
      }

      final cleanOldDigits = rawOldPhone.replaceAll(RegExp(r'\D'), '');
      final fullOldPhone = _authService.normalizePhoneNumber('${_selectedOldCountry.dialCode}$cleanOldDigits');
      final currentRegistered = _authService.normalizePhoneNumber(widget.currentPhone);

      if (fullOldPhone != currentRegistered) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Nomor WhatsApp lama yang Anda masukkan tidak sesuai dengan nomor terdaftar di akun.';
        });
        return;
      }
    }

    // 2. Validasi Nomor Baru
    if (rawNewPhone.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Masukkan nomor WhatsApp baru Anda.';
      });
      return;
    }

    final cleanNewDigits = rawNewPhone.replaceAll(RegExp(r'\D'), '');
    final fullNewPhone = _authService.normalizePhoneNumber('${_selectedNewCountry.dialCode}$cleanNewDigits');

    if (_hasCurrentPhone) {
      final cleanOldDigits = rawOldPhone.replaceAll(RegExp(r'\D'), '');
      final fullOldPhone = _authService.normalizePhoneNumber('${_selectedOldCountry.dialCode}$cleanOldDigits');
      if (fullNewPhone == fullOldPhone) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Nomor WhatsApp baru tidak boleh sama dengan nomor lama.';
        });
        return;
      }
    }

    if (cleanNewDigits.length < 8) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Nomor WhatsApp baru tidak valid (minimal 8 digit setelah kode negara).';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Sesi login tidak aktif. Silakan masuk kembali.';
      }

      // 3. Verifikasi kecocokan kata sandi akun ke Firebase Authentication
      String authEmail = user.email ?? '';
      if (authEmail.isEmpty) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = doc.data();
        final regEmail = (data?['email'] as String?)?.trim();
        final storedAuth = (data?['authEmail'] as String?)?.trim();
        if (storedAuth != null && storedAuth.isNotEmpty) {
          authEmail = storedAuth;
        } else if (regEmail != null && regEmail.isNotEmpty) {
          authEmail = regEmail;
        } else {
          final registeredPhone = _authService.normalizePhoneNumber(widget.currentPhone);
          final cleanDigits = registeredPhone.replaceAll('+', '');
          authEmail = '$cleanDigits@rideon.id';
        }
      }

      final credential = EmailAuthProvider.credential(
        email: authEmail,
        password: password,
      );

      try {
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          throw 'Kata sandi akun yang Anda masukkan salah.';
        } else if (e.code == 'too-many-requests') {
          throw 'Terlalu banyak percobaan. Silakan coba lagi beberapa saat.';
        } else {
          throw e.message ?? 'Verifikasi kata sandi gagal.';
        }
      }

      // 4. Cek apakah nomor baru sudah terdaftar pada pengguna lain
      final isUsed = await _authService.isPhoneRegistered(fullNewPhone);
      if (isUsed) {
        throw 'Nomor WhatsApp $fullNewPhone sudah terdaftar pada akun lain.';
      }

      // 5. Kirim OTP via WhatsApp Gateway
      _targetNormalizedPhone = fullNewPhone;
      final waResult = await _waGatewayService.sendOtp(_targetNormalizedPhone);

      if (!waResult.success) {
        throw waResult.error ?? 'Gagal mengirimkan kode OTP ke WhatsApp.';
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });
      _startCountdown();

      // Beri fokus ke digit pertama
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
      final waResult = await _waGatewayService.sendOtp(_targetNormalizedPhone);
      if (!waResult.success) {
        throw waResult.error ?? 'Gagal mengirim ulang kode OTP.';
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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
    if (code.length < 6) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Masukkan 6 digit kode OTP verifikasi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final isValid = await _waGatewayService.verifyOtp(_targetNormalizedPhone, code);
      if (!isValid) {
        throw 'Kode OTP WhatsApp salah atau telah kedaluwarsa.';
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Simpan perubahan nomor ke Cloud Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'phoneNumber': _targetNormalizedPhone,
          'phoneVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. Simpan referensi authEmail di Firestore agar Smart Login tetap mengenali akun
        if (user.email != null && user.email!.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'authEmail': user.email,
          });
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nomor WhatsApp berhasil diperbarui ke $_targetNormalizedPhone!'),
          backgroundColor: const Color(0xFF6B48FC),
        ),
      );

      // Kembalikan nomor baru ke Pengaturan Akun
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

  Widget _buildOtpDigitBox(int index) {
    return Container(
      width: 44,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasError
              ? Colors.red
              : _otpControllers[index].text.isNotEmpty
                  ? const Color(0xFF6B48FC)
                  : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF17152B),
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < 5) {
                _otpFocusNodes[index + 1].requestFocus();
              } else {
                _otpFocusNodes[index].unfocus();
                _handleVerifyAndSave();
              }
            } else if (value.isEmpty && index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPhoneInputField({
    required TextEditingController controller,
    required CountryCode selectedCountry,
    required VoidCallback onCountryTap,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDCD7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // Tombol Picker Bendera & Kode Negara
          InkWell(
            onTap: onCountryTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedCountry.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    selectedCountry.dialCode,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17152B),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Color(0xFF17152B),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 22,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color(0xFF17152B).withValues(alpha: 0.25),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                PhoneNumberFormatter(),
              ],
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF17152B),
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.roboto(
                  fontSize: 13,
                  color: const Color(0xFF17152B).withValues(alpha: 0.45),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
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
                  // Info Card (Figma style)
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

                  // Error Message Banner (jika ada)
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

                  if (!_isOtpSent) ...[
                    // Step 1: Form 3 Field (Password + No Lama + No Baru)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC7BCFE),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Field 1: Konfirmasi Kata Sandi Akun dengan Eye Toggle
                          Text(
                            'Konfirmasi Kata Sandi Akun',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCD7FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                  color: Color(0xFF17152B),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: GoogleFonts.roboto(
                                      fontSize: 13,
                                      color: const Color(0xFF17152B),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Masukkan kata sandi akun',
                                      hintStyle: GoogleFonts.roboto(
                                        fontSize: 13,
                                        color: const Color(0xFF17152B).withValues(alpha: 0.45),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: const Color(0xFF17152B).withValues(alpha: 0.7),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Field 2: Nomor WhatsApp Lama (Hanya tampil jika akun sudah ada nomor sebelumnya)
                          if (_hasCurrentPhone) ...[
                            Text(
                              'Nomor WhatsApp Lama',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF17152B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPhoneInputField(
                              controller: _oldPhoneController,
                              selectedCountry: _selectedOldCountry,
                              onCountryTap: () => _showCountryPicker(isForOld: true),
                              hintText: '812 3456 7890',
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Field 3: Nomor WhatsApp Baru
                          Text(
                            'Nomor WhatsApp Baru',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPhoneInputField(
                            controller: _newPhoneController,
                            selectedCountry: _selectedNewCountry,
                            onCountryTap: () => _showCountryPicker(isForOld: false),
                            hintText: '853 2344 1080',
                          ),
                          const SizedBox(height: 24),

                          // Tombol Submit Form
                          GestureDetector(
                            onTap: _isLoading ? null : _handleSendOtp,
                            child: Container(
                              height: 44,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B1832),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'KIRIM KODE OTP WHATSAPP',
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Step 2: Form Verifikasi 6 Digit OTP WhatsApp
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC7BCFE),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Verifikasi Kode OTP WhatsApp',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Kode verifikasi telah dikirim ke $_targetNormalizedPhone',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontSize: 11.5,
                              color: const Color(0xFF17152B).withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 6 Digit Input Boxes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (i) => _buildOtpDigitBox(i)),
                          ),
                          const SizedBox(height: 20),

                          // Countdown & Resend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _countdownSeconds > 0
                                    ? 'Kirim ulang kode dalam 00:${_countdownSeconds.toString().padLeft(2, '0')}'
                                    : 'Belum menerima kode?',
                                style: GoogleFonts.roboto(
                                  fontSize: 11.5,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              if (_countdownSeconds == 0) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: _isLoading ? null : _handleResendOtp,
                                  child: Text(
                                    'Kirim Ulang',
                                    style: GoogleFonts.roboto(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1B1832),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 22),

                          // Tombol VERIFIKASI & SIMPAN NOMOR
                          GestureDetector(
                            onTap: _isLoading ? null : _handleVerifyAndSave,
                            child: Container(
                              height: 44,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B1832),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'VERIFIKASI & SIMPAN NOMOR',
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Tombol Ubah Nomor / Kembali ke Step 1
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isOtpSent = false;
                                _hasError = false;
                                _errorMessage = null;
                                for (final c in _otpControllers) {
                                  c.clear();
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'Ganti Nomor atau Masukkan Ulang Sandi',
                                style: GoogleFonts.roboto(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF17152B).withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

