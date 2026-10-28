import 'package:flutter_test/flutter_test.dart';
import 'package:rideon/features/splash/presentation/pages/splash_screen.dart';
import 'package:rideon/main.dart';

void main() {
  testWidgets('RideOn app smoke test loads SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const RideOnApp());

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
