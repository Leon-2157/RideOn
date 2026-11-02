import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rideon/features/auth/data/auth_service.dart';
import 'package:rideon/features/auth/data/wa_gateway_service.dart';

/// Business logic for Nomor WhatsApp update flow
class NomorWaLogic {
  final AuthService authService;
  final WaGatewayService waGatewayService;

  NomorWaLogic({
    AuthService? authService,
    WaGatewayService? waGatewayService,
  })  : authService = authService ?? AuthService(),
        waGatewayService = waGatewayService ?? WaGatewayService();

  Future<String> validateAndSendOtp({
    required String password,
    required String rawOldPhone,
    required String rawNewPhone,
    required String oldDialCode,
    required String newDialCode,
    required String currentPhone,
    required bool hasCurrentPhone,
  }) async {
    if (password.isEmpty) {
      throw 'Masukkan kata sandi akun untuk konfirmasi keamanan.';
    }

    if (hasCurrentPhone) {
      if (rawOldPhone.isEmpty) {
        throw 'Masukkan nomor WhatsApp lama akun Anda.';
      }

      final cleanOldDigits = rawOldPhone.replaceAll(RegExp(r'\D'), '');
      final fullOldPhone = authService.normalizePhoneNumber('$oldDialCode$cleanOldDigits');
      final currentRegistered = authService.normalizePhoneNumber(currentPhone);

      if (fullOldPhone != currentRegistered) {
        throw 'Nomor WhatsApp lama yang Anda masukkan tidak sesuai dengan nomor terdaftar di akun.';
      }
    }

    if (rawNewPhone.isEmpty) {
      throw 'Masukkan nomor WhatsApp baru Anda.';
    }

    final cleanNewDigits = rawNewPhone.replaceAll(RegExp(r'\D'), '');
    final fullNewPhone = authService.normalizePhoneNumber('$newDialCode$cleanNewDigits');

    if (hasCurrentPhone) {
      final cleanOldDigits = rawOldPhone.replaceAll(RegExp(r'\D'), '');
      final fullOldPhone = authService.normalizePhoneNumber('$oldDialCode$cleanOldDigits');
      if (fullNewPhone == fullOldPhone) {
        throw 'Nomor WhatsApp baru tidak boleh sama dengan nomor lama.';
      }
    }

    if (cleanNewDigits.length < 8) {
      throw 'Nomor WhatsApp baru tidak valid (minimal 8 digit setelah kode negara).';
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'Sesi login tidak aktif. Silakan masuk kembali.';
    }

    // Verifikasi kecocokan kata sandi akun ke Firebase Authentication
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
        final registeredPhone = authService.normalizePhoneNumber(currentPhone);
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

    // Cek apakah nomor baru sudah terdaftar pada pengguna lain
    final isUsed = await authService.isPhoneRegistered(fullNewPhone);
    if (isUsed) {
      throw 'Nomor WhatsApp $fullNewPhone sudah terdaftar pada akun lain.';
    }

    return fullNewPhone;
  }

  Future<WaOtpSendResult> sendOtp(String targetPhone) async {
    return await waGatewayService.sendOtp(targetPhone);
  }

  Future<void> verifyOtpAndSave({
    required String targetPhone,
    required String code,
  }) async {
    if (code.length < 6) {
      throw 'Masukkan 6 digit kode OTP verifikasi.';
    }

    final isValid = await waGatewayService.verifyOtp(targetPhone, code);
    if (!isValid) {
      throw 'Kode OTP WhatsApp salah atau telah kedaluwarsa.';
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'phoneNumber': targetPhone,
        'phoneVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (user.email != null && user.email!.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'authEmail': user.email,
        });
      }
    }
  }
}
