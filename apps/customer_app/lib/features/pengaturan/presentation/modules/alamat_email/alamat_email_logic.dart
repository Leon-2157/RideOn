import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rideon/features/auth/data/auth_service.dart';
import 'package:rideon/features/auth/data/email_otp_service.dart';

/// Business logic for Alamat Email update/addition flow
class AlamatEmailLogic {
  final AuthService authService;
  final EmailOtpService emailOtpService;

  AlamatEmailLogic({
    AuthService? authService,
    EmailOtpService? emailOtpService,
  })  : authService = authService ?? AuthService(),
        emailOtpService = emailOtpService ?? EmailOtpService();

  Future<String> validateAndAuthenticate({
    required String password,
    required String rawOldEmail,
    required String rawNewEmail,
    required String currentEmail,
    required bool hasCurrentEmail,
    required String userPhone,
  }) async {
    if (password.isEmpty) {
      throw 'Masukkan kata sandi akun untuk konfirmasi keamanan.';
    }

    if (hasCurrentEmail) {
      if (rawOldEmail.isEmpty) {
        throw 'Masukkan alamat email lama akun Anda.';
      }

      final registeredClean = currentEmail.trim().toLowerCase();
      if (rawOldEmail != registeredClean) {
        throw 'Alamat email lama yang Anda masukkan tidak sesuai dengan akun ini.';
      }

      if (rawNewEmail.isEmpty) {
        throw 'Masukkan alamat email baru Anda.';
      }

      if (rawNewEmail == rawOldEmail) {
        throw 'Alamat email baru tidak boleh sama dengan email lama.';
      }
    } else {
      if (rawNewEmail.isEmpty) {
        throw 'Masukkan alamat email aktif Anda.';
      }
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(rawNewEmail)) {
      throw 'Format alamat email tidak valid (contoh: user@gmail.com).';
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'Sesi login tidak aktif. Silakan masuk kembali.';
    }

    String authEmail = user.email ?? '';
    String userPhoneNumber = userPhone;

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

    final isUsed = await authService.isEmailRegistered(rawNewEmail);
    if (isUsed) {
      throw 'Alamat email $rawNewEmail sudah terdaftar pada akun lain.';
    }

    return rawNewEmail;
  }

  Future<EmailOtpSendResult> sendOtp(String targetEmail) async {
    return await emailOtpService.sendOtp(targetEmail);
  }

  Future<void> verifyOtpAndSave({
    required String targetEmail,
    required String code,
  }) async {
    if (code.length < 6) {
      throw 'Masukkan 6 digit kode OTP verifikasi.';
    }

    final verifyResult = await emailOtpService.verifyOtp(targetEmail, code);
    if (!verifyResult.success) {
      throw verifyResult.error ?? 'Kode OTP salah atau telah kedaluwarsa.';
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': targetEmail,
        'emailVerified': true,
        'authEmail': targetEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
