import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideon/features/auth/presentation/pages/login_screen.dart';

void main() {
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
  });
}
