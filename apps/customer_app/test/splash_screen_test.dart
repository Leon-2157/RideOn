import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideon/features/splash/presentation/pages/splash_screen.dart';

void main() {
  testWidgets('SplashScreen animates circle expansion and calls onAnimationComplete', (tester) async {
    tester.view.physicalSize = const Size(1080, 2460);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          onAnimationComplete: () {
            completed = true;
          },
        ),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(completed, isFalse);

    // Pump multiple frames across 2.5 seconds to advance the animation smoothly
    for (int i = 0; i < 28; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(completed, isTrue);
  });
}
