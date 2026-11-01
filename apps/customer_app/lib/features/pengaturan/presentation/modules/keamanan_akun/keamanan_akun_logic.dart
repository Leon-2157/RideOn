import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rideon/features/auth/data/auth_service.dart';

/// Business logic for Keamanan Akun password update
class KeamananAkunLogic {
  final AuthService authService = AuthService();

  void validatePasswords({
    required String oldPass,
    required String newPass,
    required String confirmPass,
  }) {
    if (oldPass.trim().isEmpty) {
      throw 'Masukkan kata sandi saat ini.';
    }

    if (newPass.length < 8) {
      throw 'Kata sandi baru minimal 8 karakter.';
    }

    if (newPass == oldPass) {
      throw 'Kata sandi baru tidak boleh sama dengan kata sandi saat ini.';
    }

    if (confirmPass != newPass) {
      throw 'Konfirmasi kata sandi baru tidak cocok.';
    }
  }

  Future<void> updatePassword({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required String oldPass,
    required String newPass,
  }) async {
    final user = auth.currentUser;
    if (user == null) {
      throw 'Sesi login tidak aktif. Silakan masuk kembali.';
    }

    String authEmail = (user.email ?? '').trim().toLowerCase();
    if (authEmail.isEmpty) {
      try {
        final doc = await firestore.collection('users').doc(user.uid).get();
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
          final registeredPhone = authService.normalizePhoneNumber(userPhone);
          final cleanDigits = registeredPhone.replaceAll('+', '');
          authEmail = '$cleanDigits@rideon.id';
        }
      } catch (_) {
        final userPhone = user.phoneNumber ?? '';
        final registeredPhone = authService.normalizePhoneNumber(userPhone);
        final cleanDigits = registeredPhone.replaceAll('+', '');
        authEmail = '$cleanDigits@rideon.id';
      }
    }

    final credential = EmailAuthProvider.credential(
      email: authEmail,
      password: oldPass,
    );

    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'Kata sandi saat ini yang Anda masukkan salah.';
      } else if (e.code == 'too-many-requests') {
        throw 'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat.';
      } else {
        throw e.message ?? 'Verifikasi kata sandi saat ini gagal.';
      }
    }

    try {
      await user.updatePassword(newPass);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw 'Kata sandi baru terlalu lemah. Gunakan kombinasi huruf dan angka.';
      } else if (e.code == 'requires-recent-login') {
        throw 'Sesi keamanan Anda telah kedaluwarsa. Silakan masuk kembali.';
      } else {
        throw e.message ?? 'Gagal memperbarui kata sandi.';
      }
    }

    try {
      await firestore.collection('users').doc(user.uid).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
