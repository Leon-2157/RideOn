import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideon/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:rideon/features/auth/presentation/pages/login_screen.dart';
import 'package:rideon/features/auth/presentation/pages/register_screen.dart';

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
    testWidgets('RegisterScreen tests validation, terms modal, and success modal', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      expect(find.text('Daftar Akun'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('No. WhatsApp Aktif'), findsOneWidget);
      expect(find.text('Kata sandi (Min. 8 karakter)'), findsOneWidget);
      expect(find.text('Ulangi Kata Sandi'), findsOneWidget);

      // 1. Submit empty -> error banner (figma: error.png)
      await tester.tap(find.byKey(const Key('btn_buat_akun')));
      await tester.pumpAndSettle();
      expect(
        find.text('Pendaftaran gagal. Mohon lengkapi dan periksa kembali data Anda.'),
        findsOneWidget,
      );

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

      // 3. Fill valid details
      await tester.enterText(find.byKey(const Key('input_register_name')), 'Ahmad Budi');
      await tester.enterText(find.byKey(const Key('input_register_phone')), '081234567890');
      await tester.enterText(find.byKey(const Key('input_register_password')), 'password123');
      await tester.enterText(find.byKey(const Key('input_register_confirm_password')), 'password123');
      await tester.pumpAndSettle();

      // Submit valid registration -> shows Berhasil Daftar modal (figma: berhasil daftar.png)
      await tester.tap(find.byKey(const Key('btn_buat_akun')));
      await tester.pumpAndSettle();

      expect(find.text('Akun berhasil dibuat!'), findsOneWidget);
      expect(find.byKey(const Key('btn_masuk_sekarang_success')), findsOneWidget);

      // Tap MASUK SEKARANG to finish
      await tester.tap(find.byKey(const Key('btn_masuk_sekarang_success')));
      await tester.pumpAndSettle();
    });
  });

  group('ForgotPasswordScreen Tests', () {
    testWidgets('ForgotPasswordScreen completes OTP and new password flow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );

      // 1. Step 1: Lupa kata sandi.png
      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('input_forgot_identifier')), 'user@rideon.com');
      await tester.tap(find.byKey(const Key('btn_kirim_kode_otp')));
      await tester.pumpAndSettle();

      // 2. Step 2: Verifikasi WhatsApp (figma: verif.png / verif angka.png)
      expect(find.text('Verifikasi WhatsApp'), findsOneWidget);
      expect(find.text('KONFIRMASI'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_verifikasi_otp')));
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
