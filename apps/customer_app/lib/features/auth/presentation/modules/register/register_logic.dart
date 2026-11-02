import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/auth_service.dart';
import '../../../data/wa_gateway_service.dart';


enum RegisterStep {
  form,
  verifyOtp,
}

/// Business logic for Register flow
class RegisterLogic {
  final AuthService authService;
  final WaGatewayService waGatewayService;

  RegisterLogic({
    AuthService? authService,
    WaGatewayService? waGatewayService,
  })  : authService = authService ?? AuthService(),
        waGatewayService = waGatewayService ?? WaGatewayService();

  bool isNameValid(String name) => name.trim().length >= 3;

  bool isEmailValid(String email) {
    final text = email.trim();
    if (text.isEmpty) return true;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text);
  }

  bool isPhoneValid(String rawPhone) =>
      rawPhone.replaceAll(' ', '').length >= 9;

  bool isPasswordValid(String password) => password.length >= 8;

  bool isConfirmPasswordValid(String password, String confirmPassword) =>
      confirmPassword.isNotEmpty && confirmPassword == password;

  bool isFormValid({
    required String name,
    required String email,
    required String rawPhone,
    required String password,
    required String confirmPassword,
    required bool isTermsAgreed,
  }) {
    return isNameValid(name) &&
        isEmailValid(email) &&
        isPhoneValid(rawPhone) &&
        isPasswordValid(password) &&
        isConfirmPasswordValid(password, confirmPassword) &&
        isTermsAgreed;
  }

  String formatFullPhone(String dialCode, String rawPhone) {
    final cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    return '$dialCode$cleanDigits';
  }

  String formatCountdown(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  String getValidationErrorMessage({
    required bool isTermsAgreed,
    required String name,
    required String rawPhone,
    required String password,
    required String confirmPassword,
  }) {
    if (!isTermsAgreed) {
      return 'Anda harus menyetujui Syarat & Ketentuan RideOn untuk mendaftar.';
    } else if (!isNameValid(name)) {
      return 'Nama lengkap minimal 3 karakter.';
    } else if (!isPhoneValid(rawPhone)) {
      return 'Nomor WhatsApp minimal 9 digit.';
    } else if (!isPasswordValid(password)) {
      return 'Kata sandi minimal 8 karakter.';
    } else if (!isConfirmPasswordValid(password, confirmPassword)) {
      return 'Konfirmasi kata sandi tidak cocok. Mohon periksa kembali.';
    }
    return 'Mohon periksa kembali data pendaftaran Anda.';
  }

  Future<void> validatePhoneAndEmailUniqueness({
    required String fullPhone,
    required String email,
  }) async {
    final phoneInUse = await authService.isPhoneRegistered(fullPhone);
    if (phoneInUse) {
      throw 'Nomor WhatsApp ini sudah terdaftar. Silakan masuk.';
    }

    final trimmedEmail = email.trim();
    if (trimmedEmail.isNotEmpty) {
      final emailInUse = await authService.isEmailRegistered(trimmedEmail);
      if (emailInUse) {
        throw 'Alamat email ini sudah terdaftar. Silakan gunakan email lain.';
      }
    }
  }

  Future<WaOtpSendResult> sendWhatsAppOtp(String fullPhone) async {
    return await waGatewayService.sendOtp(fullPhone);
  }

  Future<void> sendSmsOtp({
    required String fullPhone,
    int? resendToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException error) onVerificationFailed,
    required void Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    await authService.sendPhoneOtp(
      phoneNumber: fullPhone,
      resendToken: resendToken,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
      onVerificationCompleted: onVerificationCompleted,
    );
  }

  Future<bool> verifyWhatsAppOtp(String fullPhone, String code) async {
    return await waGatewayService.verifyOtp(fullPhone, code);
  }

  Future<void> verifySmsOtp(String verificationId, String code) async {
    await authService.verifyPhoneOtpCode(
      verificationId: verificationId,
      smsCode: code,
    );
  }

  Future<void> completeRegistration({
    required String name,
    required String? email,
    required String fullPhone,
    required String password,
  }) async {
    await authService.registerCustomerAccount(
      fullName: name,
      email: (email != null && email.isNotEmpty) ? email : null,
      phoneNumber: fullPhone,
      password: password,
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    return await authService.signInWithGoogle();
  }

  String getHumanReadablePhoneAuthError(FirebaseAuthException error) {
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
}
