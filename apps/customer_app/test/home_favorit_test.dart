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

    // Verify 3 core services and ensure ServicesHeaderSection rendered only once (no duplicate)
    expect(find.byType(ServicesHeaderSection), findsOneWidget);
    expect(find.text('FlexRide'), findsOneWidget);
    expect(find.text('FlexFood'), findsWidgets);
    expect(find.text('FlexSend'), findsOneWidget);

    // Verify sections and food card details
    expect(find.text('Cek promo sekarang'), findsOneWidget);
    expect(find.text('Pilihan Terlaris'), findsOneWidget);
    expect(find.text('Rekomendasi wisata'), findsOneWidget);
    expect(find.byType(FoodCardItem), findsWidgets);
    expect(find.text('Bakso Urat'), findsOneWidget);
    expect(find.text('Rp 25.000'), findsOneWidget);
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

  testWidgets('BerandaScreen renders guest Login button when isLoggedIn is false and triggers callback', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool loginTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: BerandaScreen(
          isLoggedIn: false,
          onLoginTap: () {
            loginTapped = true;
          },
        ),
      ),
    );

    // Verify Login button exists in header
    expect(find.text('Login'), findsOneWidget);

    // Tap Login button
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(loginTapped, isTrue);
  });

  testWidgets('FavoritScreen renders back button and triggers onBack callback', (WidgetTester tester) async {
    bool backTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: FavoritScreen(
          onBack: () {
            backTapped = true;
          },
        ),
      ),
    );

    // Verify back button exists with arrow_back_rounded
    final backBtn = find.byIcon(Icons.arrow_back_rounded);
    expect(backBtn, findsOneWidget);

    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(backTapped, isTrue);
  });

  testWidgets('MainScreen Favorit tab back button switches to Beranda tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainScreen(),
      ),
    );

    // Switch to Favorit tab
    await tester.tap(find.text('Favorite'));
    await tester.pumpAndSettle();
    expect(find.byType(FavoritScreen), findsOneWidget);

    // Tap back button in FavoritScreen
    final backBtn = find.byIcon(Icons.arrow_back_rounded);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // Verify switched back to Beranda tab
    expect(find.text('FlexRide'), findsOneWidget);
  });

  testWidgets('FavoritScreen has zero overflow across screen widths (320, 360, 392.7, 412, 428)', (WidgetTester tester) async {
    final screenWidths = [320.0, 360.0, 392.7, 412.0, 428.0];

    for (final width in screenWidths) {
      tester.view.physicalSize = Size(width * 2.0, 800.0 * 2.0);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: FavoritScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Overflow occurred on width $width');
      expect(find.byType(FavoriteCardWidget), findsWidgets);
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('FavoritScreen has zero overflow under realistic device status bar padding and font scaling', (WidgetTester tester) async {
    for (final screenWidth in [320.0, 360.0]) {
      for (final fontScale in [1.0, 1.15, 1.25, 1.35]) {
        for (final topPadding in [24.0, 48.0]) {
          tester.view.physicalSize = Size(screenWidth * 2.0, 800.0 * 2.0);
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: Size(screenWidth, 800.0),
                padding: EdgeInsets.only(top: topPadding),
                textScaler: TextScaler.linear(fontScale),
              ),
              child: const MaterialApp(
                home: FavoritScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull,
              reason: 'Failed on width $screenWidth with fontScale=$fontScale and topPadding=$topPadding');
        }
      }
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}


