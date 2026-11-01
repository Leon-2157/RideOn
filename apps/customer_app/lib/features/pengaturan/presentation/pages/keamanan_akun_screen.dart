import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/pages/forgot_password_screen.dart';
import '../widgets/sub_header_widget.dart';

class KeamananAkunScreen extends StatefulWidget {
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final Future<void> Function(String oldPassword, String newPassword)? onUpdatePassword;

  const KeamananAkunScreen({
    super.key,
    this.auth,
    this.firestore,
    this.onUpdatePassword,
  });

  @override
  State<KeamananAkunScreen> createState() => _KeamananAkunScreenState();
}

class _KeamananAkunScreenState extends State<KeamananAkunScreen> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _authService = AuthService();

  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => widget.firestore ?? FirebaseFirestore.instance;

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleSavePassword() async {
    final oldPass = _oldPassController.text;
    final newPass = _newPassController.text;
    final confirmPass = _confirmPassController.text;

    // 1. Validasi kata sandi saat ini tidak boleh kosong
    if (oldPass.trim().isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Masukkan kata sandi saat ini.';
      });
      return;
    }

    // 2. Validasi kata sandi baru minimal 8 karakter
    if (newPass.length < 8) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Kata sandi baru minimal 8 karakter.';
      });
      return;
    }

    // 3. Validasi kata sandi baru tidak boleh sama dengan kata sandi saat ini
    if (newPass == oldPass) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Kata sandi baru tidak boleh sama dengan kata sandi saat ini.';
      });
      return;
    }

    // 4. Validasi konfirmasi kata sandi baru harus cocok
    if (confirmPass != newPass) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Konfirmasi kata sandi baru tidak cocok.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      if (widget.onUpdatePassword != null) {
        await widget.onUpdatePassword!(oldPass, newPass);
      } else {
        final user = _auth.currentUser;
        if (user == null) {
          throw 'Sesi login tidak aktif. Silakan masuk kembali.';
        }

        // Tentukan authEmail akun
        String authEmail = (user.email ?? '').trim().toLowerCase();
        if (authEmail.isEmpty) {
          try {
            final doc = await _firestore.collection('users').doc(user.uid).get();
            final data = doc.data();
            final storedAuth = (data?['authEmail'] as String?)?.trim();
            final regEmail = (data?['email'] as String?)?.trim();
            final phoneInDoc = (data?['phoneNumber'] as String?)?.trim();

            if (storedAuth != null && storedAuth.isNotEmpty) {
              authEmail = storedAuth.toLowerCase();
            } else if (regEmail != null && regEmail.isNotEmpty) {
              authEmail = regEmail.toLowerCase();
            } else {
              final userPhone = phoneInDoc ?? user.phoneNumber ?? '';
              final registeredPhone = _authService.normalizePhoneNumber(userPhone);
              final cleanDigits = registeredPhone.replaceAll('+', '');
              authEmail = '$cleanDigits@rideon.id';
            }
          } catch (_) {
            final userPhone = user.phoneNumber ?? '';
            final registeredPhone = _authService.normalizePhoneNumber(userPhone);
            final cleanDigits = registeredPhone.replaceAll('+', '');
            authEmail = '$cleanDigits@rideon.id';
          }
        }

        if (authEmail.isEmpty || authEmail == '@rideon.id') {
          throw 'Tidak dapat menemukan kredensial akun. Silakan masuk kembali.';
        }

        // Re-authenticate user via EmailAuthProvider credential
        final credential = EmailAuthProvider.credential(
          email: authEmail,
          password: oldPass,
        );

        await user.reauthenticateWithCredential(credential);

        // Perbarui kata sandi di Firebase Authentication
        await user.updatePassword(newPass);

        // Update metadata di Firestore /users/{uid}
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'passwordUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Firestore update passwordUpdatedAt error: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Tampilkan dialog modal sukses
      final dialogResult = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              Navigator.of(dialogCtx).pop(true);
            }
          },
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                decoration: BoxDecoration(
                  color: const Color(0xFFC7BCFE),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Kata Sandi Berhasil Diperbarui!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1832),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kata sandi akun Anda telah berhasil diperbarui. Gunakan kata sandi baru ini untuk masuk ke akun RideOn berikutnya.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: const Color(0xFF332F4C),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.of(dialogCtx).pop(true),
                      child: Container(
                        height: 44,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1832),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'SELESAI',
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
            ),
          ),
        ),
      );

      if (dialogResult == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Kata sandi saat ini yang Anda masukkan salah.';
      } else if (e.code == 'weak-password') {
        message = 'Kata sandi baru terlalu lemah.';
      } else if (e.code == 'too-many-requests') {
        message = 'Terlalu banyak percobaan. Silakan coba lagi beberapa saat.';
      } else if (e.code == 'requires-recent-login') {
        message = 'Sesi Anda telah berakhir. Silakan masuk kembali.';
      } else if (e.code == 'network-request-failed') {
        message = 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
      } else {
        message = e.message ?? 'Verifikasi kata sandi saat ini gagal.';
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = message;
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
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            buildSubHeader(
              context,
              'Keamanan Akun',
              onBack: _isLoading ? () {} : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC7BCFE),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                      Text(
                        'Kata Sandi Saat ini *',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPasswordInput(
                        key: const Key('field_old_password'),
                        controller: _oldPassController,
                        hintText: 'Masukkan sandi saat ini',
                        obscure: _obscureOld,
                        enabled: !_isLoading,
                        onChanged: (_) => _onFieldChanged(),
                        onToggle: () => setState(() => _obscureOld = !_obscureOld),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          key: const Key('link_lupa_kata_sandi'),
                          onTap: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                          child: Text(
                            'Lupa kata sandi?',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF17152B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Kata Sandi Baru *',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPasswordInput(
                        key: const Key('field_new_password'),
                        controller: _newPassController,
                        hintText: 'Minimal 8 karakter',
                        obscure: _obscureNew,
                        enabled: !_isLoading,
                        onChanged: (_) => _onFieldChanged(),
                        onToggle: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                      const SizedBox(height: 18),

                      Text(
                        'Konfirmasi Sandi Baru',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF17152B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPasswordInput(
                        key: const Key('field_confirm_password'),
                        controller: _confirmPassController,
                        hintText: 'Ketik ulang sandi baru',
                        obscure: _obscureConfirm,
                        enabled: !_isLoading,
                        onChanged: (_) => _onFieldChanged(),
                        onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      const SizedBox(height: 24),

                      GestureDetector(
                        onTap: _isLoading ? null : _handleSavePassword,
                        child: Container(
                          height: 44,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _isLoading
                                ? const Color(0xFF1B1832).withValues(alpha: 0.7)
                                : const Color(0xFF1B1832),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'SIMPAN SANDI BARU',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordInput({
    Key? key,
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    required VoidCallback onToggle,
    bool enabled = true,
    ValueChanged<String>? onChanged,
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        key: key,
        controller: controller,
        enabled: enabled,
        obscureText: obscure,
        onChanged: onChanged,
        style: GoogleFonts.roboto(fontSize: 13, color: const Color(0xFF17152B)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.roboto(fontSize: 12, color: const Color(0xFF6B6680)),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: const Color(0xFF17152B),
            ),
            onPressed: enabled ? onToggle : null,
          ),
        ),
      ),
    );
  }
}

