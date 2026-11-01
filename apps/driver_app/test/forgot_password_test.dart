import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/screens/login_screen.dart';
import 'package:driver_app/screens/forgot_password/forgot_password_screen.dart';
import 'package:driver_app/screens/forgot_password/otp_verification_screen.dart';
import 'package:driver_app/screens/forgot_password/reset_password_screen.dart';
import 'package:driver_app/screens/forgot_password/reset_password_success_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Alur Lupa Kata Sandi & Verifikasi OTP Tests (Figma HalamanLogin)', () {
    testWidgets('LoginScreen tapping Lupa kata sandi? navigates to ForgotPasswordScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Pastikan link "Lupa kata sandi?" tampil
      expect(find.byKey(const Key('link_lupa_kata_sandi')), findsOneWidget);

      // Tap link Lupa kata sandi?
      await tester.tap(find.byKey(const Key('link_lupa_kata_sandi')));
      await tester.pumpAndSettle();

      // Memastikan navigasi ke ForgotPasswordScreen berhasil
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen renders UI matching Figma (Lupa kata sandi.png)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );

      // Verifikasi komponen Figma
      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(
        find.text(
          'Masukkan nomor WhatsApp atau alamat email\nyang terdaftar di akun RideOn Anda.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('input_forgot_identifier')), findsOneWidget);
      expect(find.byKey(const Key('btn_kirim_kode_otp')), findsOneWidget);
      expect(find.text('KIRIM KODE OTP'), findsOneWidget);
      expect(find.byKey(const Key('link_kembali_ke_login')), findsOneWidget);

      // Input email/WhatsApp dan kirim OTP
      await tester.enterText(
        find.byKey(const Key('input_forgot_identifier')),
        'jutama937@gmail.com',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_kirim_kode_otp')));
      await tester.pumpAndSettle();

      // Navigasi ke OtpVerificationScreen
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      expect(find.text('Verifikasi WhatsApp'), findsOneWidget);
    });

    testWidgets('OtpVerificationScreen renders UI matching Figma (verif.png & verif angka.png)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OtpVerificationScreen(identifier: '08123456789'),
        ),
      );

      expect(find.text('Verifikasi WhatsApp'), findsOneWidget);
      expect(
        find.text('Masukkan OTP yang dikirim ke WhatsApp Anda.'),
        findsOneWidget,
      );
      expect(find.text('Kode kadaluarsa dalam'), findsOneWidget);
      expect(find.text('5:00'), findsOneWidget);
      expect(find.byKey(const Key('btn_verifikasi_otp')), findsOneWidget);

      // Kondisi awal menampilkan 6 titik (verif.png)
      expect(find.text('●'), findsNWidgets(6));

      // Masukkan 6 angka OTP (verif angka.png)
      await tester.enterText(
        find.byKey(const Key('input_otp_code')),
        '123456',
      );
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);

      // Tekan tombol verifikasi
      await tester.tap(find.byKey(const Key('btn_verifikasi_otp')));
      await tester.pumpAndSettle();

      // Navigasi ke ResetPasswordScreen
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
    });

    testWidgets('OtpVerificationScreen displays error banner matching Figma (verif salah.png)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OtpVerificationScreen(showErrorBanner: true),
        ),
      );

      expect(
        find.text('Kode OTP WhatsApp tidak valid.'),
        findsOneWidget,
      );
    });

    testWidgets('ResetPasswordScreen renders UI & toggles visibility matching Figma (sandi baru.png)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );

      expect(find.text('Buat Kata Sandi Baru'), findsOneWidget);
      expect(
        find.text('Pastikan sandi baru Anda kuat dan mudah diingat'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('input_new_password')), findsOneWidget);
      expect(find.byKey(const Key('input_confirm_new_password')), findsOneWidget);
      expect(find.byKey(const Key('btn_simpan_sandi_baru')), findsOneWidget);

      // Kondisi awal password tersembunyi
      final newPassField = tester.widget<TextField>(
        find.byKey(const Key('input_new_password')),
      );
      expect(newPassField.obscureText, isTrue);

      // Toggle lihat password baru
      await tester.tap(find.byKey(const Key('toggle_new_password')));
      await tester.pump();

      final newPassFieldVisible = tester.widget<TextField>(
        find.byKey(const Key('input_new_password')),
      );
      expect(newPassFieldVisible.obscureText, isFalse);
    });

    testWidgets('ResetPasswordScreen shows error when passwords mismatch (sandi baru 1.png)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('input_new_password')),
        '1234Abcd',
      );
      await tester.enterText(
        find.byKey(const Key('input_confirm_new_password')),
        'berbeda123',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('btn_simpan_sandi_baru')));
      await tester.pump();

      expect(find.text('Sandi tidak sesuai.'), findsOneWidget);
    });

    testWidgets('ResetPasswordSuccessScreen renders UI & navigates back to LoginScreen (ubah sandi success.png)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordSuccessScreen(),
        ),
      );

      expect(find.text('Berhasil Diubah!'), findsOneWidget);
      expect(
        find.text(
          'Kata sandi akun Anda telah berhasil diperbarui.\nSilakan masuk menggunakan kata sandi yang baru.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('btn_masuk_sekarang')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_masuk_sekarang')));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
