import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/pages/forgot_password_screen.dart';
import '../widgets/sub_header_widget.dart';
import '../modules/keamanan_akun/keamanan_akun_logic.dart';
import '../modules/keamanan_akun/keamanan_form_card.dart';
import '../modules/keamanan_akun/keamanan_success_dialog.dart';

export '../modules/keamanan_akun/keamanan_akun_logic.dart';
export '../modules/keamanan_akun/keamanan_form_card.dart';
export '../modules/keamanan_akun/keamanan_success_dialog.dart';

/// Screen Ubah Kata Sandi Akun (Slim Coordinator)
class KeamananAkunScreen extends StatefulWidget {
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final Future<void> Function(String oldPassword, String newPassword)?
      onUpdatePassword;

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
  final KeamananAkunLogic _logic = KeamananAkunLogic();

  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      widget.firestore ?? FirebaseFirestore.instance;

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

    try {
      _logic.validatePasswords(
        oldPass: oldPass,
        newPass: newPass,
        confirmPass: confirmPass,
      );
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
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
        await _logic.updatePassword(
          auth: _auth,
          firestore: _firestore,
          oldPass: oldPass,
          newPass: newPass,
        );
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      await KeamananSuccessDialog.show(context);
      if (mounted) {
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
        message = e.message ?? 'Terjadi kesalahan saat memperbarui kata sandi.';
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          buildSubHeader(context, 'Keamanan Akun'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: KeamananFormCard(
                oldPassController: _oldPassController,
                newPassController: _newPassController,
                confirmPassController: _confirmPassController,
                obscureOld: _obscureOld,
                obscureNew: _obscureNew,
                obscureConfirm: _obscureConfirm,
                isLoading: _isLoading,
                hasError: _hasError,
                errorMessage: _errorMessage,
                onToggleOld: () => setState(() => _obscureOld = !_obscureOld),
                onToggleNew: () => setState(() => _obscureNew = !_obscureNew),
                onToggleConfirm: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                onFieldChanged: _onFieldChanged,
                onForgotPassword: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                onSavePassword: _handleSavePassword,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
