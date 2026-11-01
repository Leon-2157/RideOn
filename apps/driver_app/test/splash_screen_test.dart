import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/screens/splash_screen_login.dart';
import 'package:driver_app/screens/splash_screen_navbar.dart';
import 'package:driver_app/screens/login_screen.dart';

void main() {
  group('SplashScreen Navigation and Tap Tests', () {
    testWidgets('Tapping SplashScreenLogin immediately navigates to LoginScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreenLogin(),
        ),
      );

      expect(find.byType(SplashScreenLogin), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Tap on the splash screen
      await tester.tap(find.byType(SplashScreenLogin));
      await tester.pumpAndSettle();

      // Should now be on LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SplashScreenLogin), findsNothing);
    });

    testWidgets('SplashScreenLogin automatically navigates to LoginScreen on timer completion',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreenLogin(
            initialDelay: Duration(milliseconds: 100),
            transitionDuration: Duration(milliseconds: 200),
            endDuration: Duration(milliseconds: 100),
          ),
        ),
      );

      expect(find.byType(SplashScreenLogin), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Advance time through initialDelay + transitionDuration + endDuration
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Tapping SplashScreenLogin triggers onCompleted callback if provided',
        (WidgetTester tester) async {
      bool completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreenLogin(
            onCompleted: () {
              completed = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(SplashScreenLogin));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('Tapping SplashScreenNavbar immediately navigates to LoginScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreenNavbar(),
        ),
      );

      expect(find.byType(SplashScreenNavbar), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      await tester.tap(find.byType(SplashScreenNavbar));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
