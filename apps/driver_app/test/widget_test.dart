import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/main.dart';
import 'package:driver_app/screens/splash_screen_navbar.dart';

void main() {
  testWidgets('SplashScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RideOnDriverApp());
    expect(find.byType(SplashScreenNavbar), findsOneWidget);
  });
}
