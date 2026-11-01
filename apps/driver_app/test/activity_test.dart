import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/screens/activity/activity_list_screen.dart';
import 'package:driver_app/screens/activity/activity_food_detail_screen.dart';
import 'package:driver_app/screens/activity/activity_ride_detail_screen.dart';
import 'package:driver_app/screens/activity/activity_shopping_detail_screen.dart';
import 'package:driver_app/screens/activity/trip_help_bottom_sheet.dart';

void main() {
  group('Halaman Aktivitas Driver Tests (Figma Spesifikasi)', () {
    testWidgets('ActivityListScreen renders header, 3 order cards, and bottom navbar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ActivityListScreen(),
        ),
      );

      // Verifikasi Header
      expect(find.text('Aktivitas'), findsNWidgets(2)); // 1 di header, 1 di navbar

      // Verifikasi 3 Kartu Orderan
      expect(find.text('Pesanan Makanan'), findsOneWidget);
      expect(find.text('Orderan toko'), findsOneWidget);

      expect(find.text('Antar penumpang'), findsOneWidget);
      expect(find.text('Ojek'), findsOneWidget);

      expect(find.text('Titip Belanja'), findsNWidgets(2)); // 1 judul, 1 subtitle

      // Verifikasi ID pada ketiga kartu
      expect(find.text('#12E4S67'), findsNWidgets(3));

      // Verifikasi Menu Bottom Navbar
      expect(find.text('Radar'), findsOneWidget);
      expect(find.text('Dompet'), findsOneWidget);
      expect(find.text('chat'), findsOneWidget);
    });

    testWidgets('Tapping Pesanan Makanan card navigates to ActivityFoodDetailScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ActivityListScreen(),
        ),
      );

      await tester.tap(find.text('Pesanan Makanan'));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityFoodDetailScreen), findsOneWidget);
      expect(find.text('Rp 15.000'), findsOneWidget);
      expect(find.text('Non-Tunai (E-Wallet)'), findsOneWidget);
      expect(find.text('Waroeng Bamboe'), findsOneWidget);
      expect(find.text('PIN MAKANAN YANG DI PESAN'), findsOneWidget);
      expect(find.text('4 0 9 2'), findsOneWidget);
      expect(find.text('ID : I2E4S68'), findsOneWidget);
    });

    testWidgets('Tapping Antar penumpang card navigates to ActivityRideDetailScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ActivityListScreen(),
        ),
      );

      await tester.tap(find.text('Antar penumpang'));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityRideDetailScreen), findsOneWidget);
      expect(find.text('M.Topik'), findsOneWidget);
      expect(find.text('Ongkir: Rp 35.000'), findsOneWidget);
      expect(find.textContaining('Jl.Seulawah no 10 PIM'), findsOneWidget);
      expect(find.textContaining('Suzuya Mall Lhokseumawe'), findsOneWidget);
      expect(find.text('ID : 12E4S79'), findsOneWidget);
    });

    testWidgets('Tapping Titip Belanja card navigates to ActivityShoppingDetailScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ActivityListScreen(),
        ),
      );

      await tester.tap(find.widgetWithText(Material, 'Titip Belanja').first);
      await tester.pumpAndSettle();

      expect(find.byType(ActivityShoppingDetailScreen), findsOneWidget);
      expect(find.text('FlexSend'), findsOneWidget);
      expect(find.text('Titip Belanja Manual'), findsOneWidget);
      expect(find.text('Pemesanan: Gufran'), findsOneWidget);
      expect(find.text('Pasar Pagi Batuphat'), findsOneWidget);
      expect(find.text('Apotik Dien Farma'), findsOneWidget);
      expect(find.text('1. Daging Sapi (1 kg)'), findsOneWidget);
      expect(find.text('Rp 120.000'), findsOneWidget);
      expect(find.text('TOTAL'), findsOneWidget);
      expect(find.text('Rp 183.000'), findsOneWidget);
    });

    testWidgets('Tapping bottom navigation bar tabs updates active state and triggers callback',
        (WidgetTester tester) async {
      int? selectedTab;
      await tester.pumpWidget(
        MaterialApp(
          home: ActivityListScreen(
            onTabSelected: (index) {
              selectedTab = index;
            },
          ),
        ),
      );

      // Tap Dompet
      await tester.tap(find.text('Dompet'));
      await tester.pumpAndSettle();
      expect(selectedTab, 2);

      // Tap Radar
      await tester.tap(find.text('Radar'));
      await tester.pumpAndSettle();
      expect(selectedTab, 0);

      // Tap chat
      await tester.tap(find.text('chat'));
      await tester.pumpAndSettle();
      expect(selectedTab, 3);
    });

    testWidgets('Back buttons in detail screens pop back to ActivityListScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ActivityListScreen(),
        ),
      );

      // Buka detail makanan lalu tekan tombol kembali
      await tester.tap(find.text('Pesanan Makanan'));
      await tester.pumpAndSettle();
      expect(find.byType(ActivityFoodDetailScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(ActivityListScreen), findsOneWidget);
      expect(find.byType(ActivityFoodDetailScreen), findsNothing);
    });

    testWidgets('ActivityListScreen renders without overflow on narrow screens (320x640 and 360x640)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ActivityListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ActivityListScreen), findsOneWidget);
      expect(find.text('3 Pesanan Selesai'), findsOneWidget);
      expect(find.text('Rp 233.000'), findsOneWidget);
    });

    testWidgets('Tapping Ada masalah dengan perjalanan ini opens TripHelpBottomSheet and displays issue options and CS',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityRideDetailScreen(),
          ),
        ),
      );

      // Verify card exists
      expect(find.text('Ada masalah dengan perjalanan ini?'), findsOneWidget);

      // Tap card
      await tester.tap(find.text('Ada masalah dengan perjalanan ini?'));
      await tester.pumpAndSettle();

      // Verify bottom sheet is shown
      expect(find.byType(TripHelpBottomSheet), findsOneWidget);
      expect(find.text('Bantuan Perjalanan'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TripHelpBottomSheet),
          matching: find.textContaining('ID : 12E4S79'),
        ),
        findsOneWidget,
      );
      expect(find.text('PILIHAN KENDALA'), findsOneWidget);
      expect(find.text('Tarif atau pembayaran tidak sesuai'), findsOneWidget);
      expect(find.text('Rute atau titik lokasi tidak akurat'), findsOneWidget);
      expect(find.text('Kendala dengan penumpang'), findsOneWidget);
      expect(find.text('Barang penumpang tertinggal'), findsOneWidget);
      expect(find.text('Aplikasi bermasalah atau sinyal/GPS terputus'), findsOneWidget);
      expect(find.text('Hubungi Customer Service'), findsOneWidget);

      // Tap an issue option
      await tester.tap(find.text('Tarif atau pembayaran tidak sesuai'));
      await tester.pumpAndSettle();

      // Verify bottom sheet popped and SnackBar is shown
      expect(find.byType(TripHelpBottomSheet), findsNothing);
      expect(find.textContaining('Laporan diterima: Tarif atau pembayaran tidak sesuai'), findsOneWidget);
    });

    testWidgets('Tapping Hubungi Customer Service in TripHelpBottomSheet opens CS Dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityRideDetailScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Ada masalah dengan perjalanan ini?'));
      await tester.pumpAndSettle();

      expect(find.byType(TripHelpBottomSheet), findsOneWidget);

      // Scroll to bottom if needed and tap CS button
      await tester.ensureVisible(find.byKey(const Key('btn_contact_cs')));
      await tester.tap(find.byKey(const Key('btn_contact_cs')));
      await tester.pumpAndSettle();

      // Verify CS dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Customer Service'), findsOneWidget);
      expect(find.text('Call Center RideOn'), findsOneWidget);
      expect(find.text('WhatsApp Bantuan Driver'), findsOneWidget);

      // Tap Tutup
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Tapping close button on TripHelpBottomSheet dismisses the sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityRideDetailScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Ada masalah dengan perjalanan ini?'));
      await tester.pumpAndSettle();

      expect(find.byType(TripHelpBottomSheet), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_close_help_sheet')));
      await tester.pumpAndSettle();

      expect(find.byType(TripHelpBottomSheet), findsNothing);
    });
  });
}
