import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/auth_service.dart';
import '../widgets/sub_header_widget.dart';
import '../widgets/email_verification_dialog.dart';

class AlamatEmailScreen extends StatefulWidget {
  final String currentEmail;
  final String userPhone;
  final bool isEmailVerified;

  const AlamatEmailScreen({
    super.key,
    this.currentEmail = '',
    this.userPhone = '',
    this.isEmailVerified = true,
  });

  @override
  State<AlamatEmailScreen> createState() => _AlamatEmailScreenState();
}

class _AlamatEmailScreenState extends State<AlamatEmailScreen> {
  final _passwordController = TextEditingController();
  final _oldEmailController = TextEditingController();
  final _newEmailController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  bool get _hasCurrentEmail =>
      widget.currentEmail.trim().isNotEmpty &&
      widget.currentEmail.trim() != 'Belum ditambahkan' &&
      !widget.currentEmail.endsWith('@rideon.id') &&
      widget.isEmailVerified;

  @override
  void dispose() {
    _passwordController.dispose();
    _oldEmailController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyEmail() async {
    final password = _passwordController.text.trim();
    final rawOldEmail = _oldEmailController.text.trim().toLowerCase();
    final rawNewEmail = _newEmailController.text.trim().toLowerCase();

    // 1. Validasi Kata Sandi Kosong
    if (password.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Masukkan kata sandi akun untuk konfirmasi keamanan.';
      });
      return;
    }

    // 2. Validasi Jika Ada Email Lama (Kondisi 3 Kolom)
    if (_hasCurrentEmail) {
      if (rawOldEmail.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Masukkan alamat email lama akun Anda.';
        });
        return;
      }

      final registeredClean = widget.currentEmail.trim().toLowerCase();
      if (rawOldEmail != registeredClean) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Alamat email lama yang Anda masukkan tidak sesuai dengan akun ini.';
        });
        return;
      }

      if (rawNewEmail.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Masukkan alamat email baru Anda.';
        });
        return;
      }

      if (rawNewEmail == rawOldEmail) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Alamat email baru tidak boleh sama dengan email lama.';
        });
        return;
      }
    } else {
      // Kondisi 2 Kolom (Belum Ada Email Sebelumnya)
      if (rawNewEmail.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Masukkan alamat email aktif Anda.';
        });
        return;
      }
    }

    // 3. Validasi Format Email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(rawNewEmail)) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Format alamat email tidak valid (contoh: user@gmail.com).';
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

      // 4. Verifikasi Kata Sandi Akun ke Firebase Authentication
      String authEmail = user.email ?? '';
      String userPhoneNumber = widget.userPhone;

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      final storedAuth = (data?['authEmail'] as String?)?.trim();
      final regEmail = (data?['email'] as String?)?.trim();
      final phoneInDoc = (data?['phoneNumber'] as String?)?.trim();
      if (phoneInDoc != null && phoneInDoc.isNotEmpty) {
        userPhoneNumber = phoneInDoc;
      }

      if (authEmail.isEmpty) {
        if (storedAuth != null && storedAuth.isNotEmpty) {
          authEmail = storedAuth;
        } else if (regEmail != null && regEmail.isNotEmpty) {
          authEmail = regEmail;
        } else {
          final cleanDigits = userPhoneNumber.replaceAll(RegExp(r'\D'), '');
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
          throw e.message ?? 'Verifikasi kata sandi akun gagal.';
        }
      }

      // 5. Cek apakah email baru sudah terdaftar di Firestore
      final isUsed = await _authService.isEmailRegistered(rawNewEmail);
      if (isUsed) {
        throw 'Alamat email $rawNewEmail sudah terdaftar pada akun lain.';
      }

      // 6. Kirim tautan verifikasi ke email baru via Firebase Auth
      await user.verifyBeforeUpdateEmail(rawNewEmail);

      // CRITICAL: JANGAN SIMPAN DATA KE FIRESTORE SEBELUM EMAIL DIVERIFIKASI!

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // 7. Tampilkan Dialog Menunggu Verifikasi Email
      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => EmailVerificationDialog(
          newEmail: rawNewEmail,
          password: password,
        ),
      );

      if (verified == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alamat email $rawNewEmail berhasil diverifikasi!'),
            backgroundColor: const Color(0xFF6B48FC),
          ),
        );
        Navigator.of(context).pop(rawNewEmail);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Alamat email sudah terdaftar pada akun lain.';
          break;
        case 'invalid-email':
          msg = 'Format alamat email tidak valid.';
          break;
        case 'requires-recent-login':
          msg = 'Sesi Anda telah berakhir. Silakan masuk kembali.';
          break;
        case 'too-many-requests':
          msg = 'Terlalu banyak percobaan. Silakan tunggu beberapa saat.';
          break;
        default:
          msg = e.message ?? 'Gagal mengirim tautan verifikasi email.';
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = msg;
      });
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
          buildSubHeader(
            context,
            'Alamat Email',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7BCFE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6CEFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _hasCurrentEmail ? 'Perbarui Alamat Email' : 'Hubungkan Email Anda',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF17152B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _hasCurrentEmail
                                    ? 'Email terdaftar saat ini: ${widget.currentEmail}\nUntuk menggantinya, konfirmasi kata sandi akun, masukkan email lama, dan masukkan email baru Anda. Kami akan mengirimkan tautan verifikasi ke email baru Anda.'
                                    : 'Tambahkan alamat email resmi untuk menerima e-receipt bukti sewa transaksi. Kami akan mengirimkan tautan verifikasi ke Gmail Anda.',
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  color: const Color(0xFF17152B),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

                  // Form Card
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

                        // Jika sudah ada email sebelumnya: Tampilkan Field Email Lama
                        if (_hasCurrentEmail) ...[
                          Text(
                            'Alamat Email Lama',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          buildInputField(
                            controller: _oldEmailController,
                            hintText: 'Contoh: ${widget.currentEmail}',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Field Email Baru / Email Aktif
                        Text(
                          _hasCurrentEmail ? 'Alamat Email Baru' : 'Alamat Email Aktif',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF17152B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        buildInputField(
                          controller: _newEmailController,
                          hintText: 'peter@gmail.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),

                        // Tombol VERIFIKASI EMAIL
                        GestureDetector(
                          onTap: _isLoading ? null : _handleVerifyEmail,
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
                                      'VERIFIKASI EMAIL',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

