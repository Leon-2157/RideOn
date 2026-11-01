import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideon/features/auth/data/auth_service.dart';
import 'package:rideon/features/auth/data/wa_gateway_service.dart';
import 'package:rideon/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:rideon/features/auth/presentation/pages/login_screen.dart';
import 'package:rideon/features/auth/presentation/pages/register_screen.dart';

class FakeAuthService extends Fake implements AuthService {
  @override
  String normalizePhoneNumber(String phone) => '+6281234567890';

  @override
  Future<bool> isPhoneRegistered(String rawPhone) async => true;
}

class FakeWaGatewayService extends Fake implements WaGatewayService {
  @override
  Future<WaOtpSendResult> sendOtp(String phoneNumber, {String purpose = 'register'}) async {
    return const WaOtpSendResult(success: true);
  }

  @override
  Future<bool> verifyOtp(String phoneNumber, String code) async => true;

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String phoneNumber,
    required String newPassword,
  }) async {
    return {'success': true, 'message': 'Kata sandi berhasil diperbarui'};
  }
}

void main() {
  group('LoginScreen Tests', () {
    testWidgets('LoginScreen renders card, inputs, and buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verify key elements from Figma node 44:1917
      expect(find.text('No. WhatsApp / Email'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Lupa kata sandi?'), findsOneWidget);
      expect(find.text('MASUK'), findsOneWidget);
      expect(find.text('ATAU'), findsOneWidget);
      expect(find.text('Lanjutkan Dengan Google'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText && w.text.toPlainText().contains('Belum punya akun?')),
        findsOneWidget,
      );

      // Test validation error banner (figma: Login kata sandi salah.png)
      await tester.tap(find.byKey(const Key('btn_masuk_login')));
      await tester.pumpAndSettle();
      expect(
        find.text('Email/WhatsApp atau kata sandi yang Anda masukkan salah.'),
        findsOneWidget,
      );
    });

    testWidgets('LoginScreen navigates to RegisterScreen on tapping Daftar Sekarang', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      await tester.tap(find.byKey(const Key('link_daftar_sekarang')));
      await tester.pumpAndSettle();

      expect(find.text('Daftar Akun'), findsOneWidget);
      expect(find.text('Lengkapi data diri Anda untuk memulai'), findsOneWidget);
    });

    testWidgets('LoginScreen navigates to ForgotPasswordScreen on tapping Lupa kata sandi', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      await tester.tap(find.byKey(const Key('link_lupa_kata_sandi')));
      await tester.pumpAndSettle();

      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(find.text('KIRIM KODE OTP'), findsOneWidget);
    });
  });

  group('RegisterScreen Tests', () {
    testWidgets('RegisterScreen tests 5-field layout, country picker, password match validation, and terms modal', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      // Verify the 5 fields from updated design
      expect(find.text('Daftar Akun'), findsOneWidget);
      expect(find.text('Nama Lengkap *'), findsOneWidget);
      expect(find.text('Alamat Email (Opsional)'), findsOneWidget);
      expect(find.byKey(const Key('btn_country_picker')), findsOneWidget);
      expect(find.text('+62'), findsOneWidget);
      expect(find.text('Kata sandi (Min. 8 karakter) *'), findsOneWidget);
      expect(find.text('Ulangi Kata Sandi *'), findsOneWidget);

      // 1. Submit button is disabled (greyed out) from the start
      final btnBefore = tester.widget<ElevatedButton>(find.byKey(const Key('btn_buat_akun')));
      expect(btnBefore.onPressed, isNull);

      // 2. Open Syarat & Ketentuan modal (figma: syarat dan ketentuan.png)
      await tester.tap(find.byKey(const Key('link_syarat_ketentuan')));
      await tester.pumpAndSettle();

      expect(find.text('Syarat & Ketentuan RideOn'), findsOneWidget);
      expect(find.text('SAYA MENGERTI & SETUJU'), findsOneWidget);

      // Agree to terms -> closes modal and checks checkbox (figma: ceklis.png)
      await tester.tap(find.byKey(const Key('btn_agree_terms')));
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byKey(const Key('checkbox_terms')));
      expect(checkbox.value, isTrue);

      // 3. Still disabled because fields are not filled yet
      final btnAfterTerms = tester.widget<ElevatedButton>(find.byKey(const Key('btn_buat_akun')));
      expect(btnAfterTerms.onPressed, isNull);

      // 4. Fill valid name, phone, but mismatched passwords
      await tester.enterText(find.byKey(const Key('input_register_name')), 'Ahmad Budi');
      await tester.enterText(find.byKey(const Key('input_register_email')), 'ahmad.budi@example.com');
      await tester.enterText(find.byKey(const Key('input_register_phone')), '81234567890');
      await tester.enterText(find.byKey(const Key('input_register_password')), 'password123');
      await tester.enterText(find.byKey(const Key('input_register_confirm_password')), 'differentPassword');
      await tester.pumpAndSettle();

      // Still disabled because confirm password does not match
      final btnMismatch = tester.widget<ElevatedButton>(find.byKey(const Key('btn_buat_akun')));
      expect(btnMismatch.onPressed, isNull);

      // 5. Fix confirm password to match
      await tester.enterText(find.byKey(const Key('input_register_confirm_password')), 'password123');
      await tester.pumpAndSettle();

      // Now all 5 fields and terms are valid -> button becomes active!
      final btnActive = tester.widget<ElevatedButton>(find.byKey(const Key('btn_buat_akun')));
      expect(btnActive.onPressed, isNotNull);

      expect(find.text('Ahmad Budi'), findsOneWidget);
      expect(find.text('ahmad.budi@example.com'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is EditableText && w.controller.text == '812 3456 7890'),
        findsOneWidget,
      );
    });
  });

  group('ForgotPasswordScreen Tests', () {
    testWidgets('ForgotPasswordScreen dynamically updates button for Email input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ForgotPasswordScreen(
            authService: FakeAuthService(),
            waGatewayService: FakeWaGatewayService(),
          ),
        ),
      );

      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(find.text('KIRIM KODE OTP'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('input_forgot_identifier')), 'user@rideon.com');
      await tester.pump();

      expect(find.text('KIRIM TAUTAN RESET KE EMAIL'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen completes WhatsApp OTP and new password flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ForgotPasswordScreen(
            authService: FakeAuthService(),
            waGatewayService: FakeWaGatewayService(),
          ),
        ),
      );

      // 1. Step 1: Lupa kata sandi.png with Phone
      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('input_forgot_identifier')), '081234567890');
      await tester.pump();
      expect(find.text('KIRIM KODE OTP'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_kirim_kode_otp')));
      await tester.pumpAndSettle();

      // 2. Step 2: Verifikasi WhatsApp (figma: verif.png / verif angka.png)
      expect(find.text('Verifikasi WhatsApp'), findsOneWidget);
      expect(find.text('KONFIRMASI'), findsOneWidget);

      // Enter 6 digit OTP manually (verified no hardcoded prefill)
      for (int i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('otp_box_$i')), '${i + 1}');
      }
      await tester.pumpAndSettle();

      // 3. Step 3: Buat Kata Sandi Baru (figma: sandi baru.png)
      expect(find.text('Buat Kata Sandi Baru'), findsOneWidget);
      expect(find.text('SIMPAN SANDI BARU'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('input_new_password')), 'passwordBaru123');
      await tester.enterText(find.byKey(const Key('input_confirm_new_password')), 'passwordBaru123');
      await tester.pumpAndSettle();

      // 4. Step 4: Berhasil Diubah modal (figma: ubah sandi success.png)
      await tester.tap(find.byKey(const Key('btn_simpan_sandi_baru')));
      await tester.pumpAndSettle();

      expect(find.text('Berhasil Diubah!'), findsOneWidget);
      expect(find.byKey(const Key('btn_masuk_sekarang_reset_success')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_masuk_sekarang_reset_success')));
      await tester.pumpAndSettle();
    });
  });
}
