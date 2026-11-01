import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/screens/login_screen.dart';
import 'package:driver_app/screens/radar/radar_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen Driver Tests', () {
    testWidgets('LoginScreen renders card, inputs, and buttons matching Figma',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verifikasi komponen sesuai Figma HalamanLogin
      expect(find.text('No. WhatsApp / Email'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Lupa kata sandi?'), findsOneWidget);
      expect(find.text('MASUK'), findsOneWidget);
      expect(find.text('ATAU'), findsOneWidget);
      expect(find.text('Lanjutkan Dengan Google'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains('Belum punya akun?')),
        findsOneWidget,
      );

      // Verifikasi tombol MASUK langsung masuk tanpa logika login yang memblokir
      await tester.tap(find.byKey(const Key('btn_masuk_login')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(RadarScreen), findsOneWidget);
    });

    testWidgets(
        'LoginScreen displays error banner when showErrorBanner is true (Figma: Login kata sandi salah.png)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(showErrorBanner: true),
        ),
      );

      expect(
        find.text('Email/WhatsApp atau kata sandi yang Anda masukkan salah.'),
        findsOneWidget,
      );
    });

    testWidgets('LoginScreen Google login button navigates directly to RadarScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      await tester.tap(find.byKey(const Key('btn_google_login')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(RadarScreen), findsOneWidget);
    });

    testWidgets('LoginScreen toggles password visibility',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Kondisi awal sandi tersembunyi
      final passwordFieldInitial = tester.widget<TextField>(
        find.byKey(const Key('input_login_password')),
      );
      expect(passwordFieldInitial.obscureText, isTrue);

      // Tekan icon mata untuk melihat sandi
      await tester.tap(find.byKey(const Key('toggle_password_visibility')));
      await tester.pumpAndSettle();

      final passwordFieldVisible = tester.widget<TextField>(
        find.byKey(const Key('input_login_password')),
      );
      expect(passwordFieldVisible.obscureText, isFalse);
    });

    testWidgets('LoginScreen accepts user input in fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('input_login_identifier')),
        'Jutama937@gmail.com',
      );
      await tester.enterText(
        find.byKey(const Key('input_login_password')),
        '1234Abcd',
      );
      await tester.pumpAndSettle();

      expect(find.text('Jutama937@gmail.com'), findsOneWidget);
      expect(find.text('1234Abcd'), findsOneWidget);
    });
  });
}
