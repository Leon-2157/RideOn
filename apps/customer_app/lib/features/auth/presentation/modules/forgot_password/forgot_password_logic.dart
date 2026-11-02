import '../../../data/auth_service.dart';
import '../../../data/wa_gateway_service.dart';

/// Business logic for Forgot Password flow
class ForgotPasswordLogic {
  final AuthService authService;
  final WaGatewayService waGatewayService;

  ForgotPasswordLogic({
    AuthService? authService,
    WaGatewayService? waGatewayService,
  })  : authService = authService ?? AuthService(),
        waGatewayService = waGatewayService ?? WaGatewayService();

  bool isEmail(String text) => text.trim().contains('@');

  bool isValidEmail(String text) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text.trim());
  }

  String normalizePhone(String text) {
    return authService.normalizePhoneNumber(text);
  }

  Future<void> sendEmailReset(String email) async {
    await authService.auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<bool> isPhoneRegistered(String normalizedPhone) async {
    return await authService.isPhoneRegistered(normalizedPhone);
  }

  Future<String?> lookupMatchedEmail(String normalizedPhone) async {
    try {
      final query = await authService.firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        final regEmail = (data['email'] as String?)?.trim();
        final authEmail = (data['authEmail'] as String?)?.trim();
        if (regEmail != null && regEmail.isNotEmpty) {
          return regEmail;
        } else if (authEmail != null && authEmail.isNotEmpty) {
          return authEmail;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<WaOtpSendResult> sendWhatsAppOtp(String normalizedPhone) async {
    return await waGatewayService.sendOtp(
      normalizedPhone,
      purpose: 'reset_password',
    );
  }

  Future<bool> verifyOtp(String normalizedPhone, String otp) async {
    return await waGatewayService.verifyOtp(normalizedPhone, otp);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String normalizedPhone,
    required String newPassword,
  }) async {
    return await waGatewayService.resetPassword(
      phoneNumber: normalizedPhone,
      newPassword: newPassword,
    );
  }
}
