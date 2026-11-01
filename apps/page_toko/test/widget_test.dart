import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_toko/main.dart';
import 'package:page_toko/screens/auth/toko_login_screen.dart';
import 'package:page_toko/screens/finance/toko_finance_screen.dart';
import 'package:page_toko/screens/home/toko_home_screen.dart';
import 'package:page_toko/screens/menu/toko_menu_screen.dart';
import 'package:page_toko/screens/orders/toko_orders_screen.dart';
import 'package:page_toko/screens/profile/edit_profile_screen.dart';
import 'package:page_toko/screens/profile/toko_profile_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('TokoApp smoke test renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(const TokoApp());
    expect(find.byType(TokoApp), findsOneWidget);
  });

  testWidgets('Home renders on 360x640', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoHomeScreen())));
    expect(find.text('Warung Taufiq'), findsOneWidget);
  });

  testWidgets('Orders renders on 360x640', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoOrdersScreen())));
    expect(find.text('Pesanan'), findsOneWidget);
  });

  testWidgets('Menu renders on 360x640', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoMenuScreen())));
    expect(find.text('Daftar Menu'), findsOneWidget);
  });

  testWidgets('Finance renders on 360x640', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoFinanceScreen())));
    expect(find.text('Keuangan'), findsOneWidget);
  });

  testWidgets('Profile renders on 360x640', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoProfileScreen())));
    expect(find.text('Profil Toko'), findsOneWidget);
  });

  testWidgets('EditProfile renders on 360x640', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: EditProfileScreen()));
    expect(find.text('Ubah Profil'), findsOneWidget);
    expect(find.text('SIMPAN PERUBAHAN'), findsOneWidget);
  });

  testWidgets('Login renders on 360x640', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(home: TokoLoginScreen(onLoginSuccess: () {})));
    expect(find.text('MASUK'), findsOneWidget);
  });

  testWidgets('All screens render on ultra-compact 320x480 without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoHomeScreen())));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoOrdersScreen())));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoMenuScreen())));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoFinanceScreen())));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoProfileScreen())));
    await tester.pumpWidget(const MaterialApp(home: EditProfileScreen()));
  });
}
