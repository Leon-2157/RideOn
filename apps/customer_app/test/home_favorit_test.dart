import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideon/features/favorit/presentation/pages/favorit_screen.dart';
import 'package:rideon/features/flexfood/presentation/pages/flexfood_screen.dart';
import 'package:rideon/features/flexsend/presentation/pages/flexsend_screen.dart';
import 'package:rideon/features/home/presentation/pages/beranda_screen.dart';
import 'package:rideon/features/main/presentation/pages/main_screen.dart';

void main() {
  testWidgets('BerandaScreen renders services, promo, and wisata', (WidgetTester tester) async {
    // Set a realistic mobile device screen size for scrollable test
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: BerandaScreen(),
      ),
    );

    // Verify 3 core services
    expect(find.text('FlexRide'), findsOneWidget);
    expect(find.text('FlexFood'), findsWidgets);
    expect(find.text('FlexSend'), findsOneWidget);

    // Verify sections
    expect(find.text('Cek promo sekarang'), findsOneWidget);
    expect(find.text('Pilihan Terlaris'), findsOneWidget);
    expect(find.text('Rekomendasi wisata'), findsOneWidget);
  });

  testWidgets('FavoritScreen renders search bar and items', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FavoritScreen(),
      ),
    );

    expect(find.text('Cari Kembali favorit Mu!'), findsOneWidget);
    expect(find.text('Makanan Favoritmu ❤️'), findsOneWidget);
    expect(find.text('Daftar Favorit Tersimpan'), findsOneWidget);
  });

  testWidgets('MainScreen switches tabs between Beranda and Favorit', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainScreen(),
      ),
    );

    expect(find.byType(BerandaScreen), findsOneWidget);

    // Tap on Favorite tab
    await tester.tap(find.text('Favorite'));
    await tester.pumpAndSettle();

    expect(find.byType(FavoritScreen), findsOneWidget);
  });

  testWidgets('MainScreen navigates to FlexFood and FlexSend', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MainScreen(),
      ),
    );

    // Tap FlexFood
    await tester.tap(find.text('FlexFood').first);
    await tester.pumpAndSettle();
    expect(find.byType(FlexFoodScreen), findsOneWidget);

    // Go back
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    // Tap FlexSend
    await tester.tap(find.text('FlexSend'));
    await tester.pumpAndSettle();
    expect(find.byType(FlexSendScreen), findsOneWidget);
  });
}
