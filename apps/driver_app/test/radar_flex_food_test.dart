import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/screens/radar/radar_flex_food_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Halaman Radar FlexFood Driver Tests (Figma Spesifikasi)', () {
    testWidgets(
        'RadarFlexFoodScreen renders header, map, busy area, searching card, and bottom navbar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarFlexFoodScreen(
            enableRadarAnimation: false,
            driverName: 'Joni utama',
            plateNumber: 'BK 4892 ABC',
          ),
        ),
      );

      // Verifikasi Header Driver & GPS SIAP
      expect(find.text('Joni utama'), findsOneWidget);
      expect(find.text('BK 4892 ABC'), findsOneWidget);
      expect(find.text('GPS SIAP'), findsOneWidget);

      // Verifikasi Status Switch Online
      expect(find.text('Status: Online'), findsOneWidget);
      expect(find.text('Geser tombol untuk off'), findsOneWidget);

      // Verifikasi Area Sibuk
      expect(find.text('Area sibuk'), findsOneWidget);

      // Verifikasi Card Searching Floating Pill
      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);

      // Verifikasi Bottom Navbar (4 Tabs)
      expect(find.text('Radar'), findsOneWidget);
      expect(find.text('Aktivitas'), findsOneWidget);
      expect(find.text('Dompet'), findsOneWidget);
      expect(find.text('chat'), findsOneWidget);
    });

    testWidgets(
        'Toggling switch changes driver status between Online and Offline',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarFlexFoodScreen(
            enableRadarAnimation: false,
          ),
        ),
      );

      expect(find.text('Status: Online'), findsOneWidget);

      // Switch ke Offline
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Status: Offline'), findsOneWidget);
      expect(find.text('Geser tombol untuk on'), findsOneWidget);
      expect(
        find.text('Anda sedang Offline. Aktifkan status untuk bekerja.'),
        findsOneWidget,
      );

      // Switch kembali ke Online
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Status: Online'), findsOneWidget);
    });

    testWidgets(
        'Incoming order displays food order sheet and handles accept/reject flow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarFlexFoodScreen(
            enableRadarAnimation: false,
            initialOrderState: FlexFoodOrderState.incoming,
          ),
        ),
      );

      // Verifikasi Elemen Modal Sesuai Figma pemesanan makanan.png
      expect(find.text('ORDERAN BARU MASUK!'), findsOneWidget);
      expect(find.text('PESAN MAKANAN'), findsOneWidget);
      expect(find.text('16 Detik'), findsOneWidget);
      expect(find.text('Pendapatan Bersih'), findsOneWidget);
      expect(find.text('Rp 15.000'), findsOneWidget);
      expect(find.text('Non-Tunai (E-Wallet)'), findsOneWidget);
      expect(find.text('Waroeng Bamboe'), findsAtLeastNWidgets(1));
      expect(find.text('Jl. Dumai, ARUN No. 101 (Fikri)'), findsOneWidget);
      expect(find.text('Total Jarak Tempuh: 4.2 km Estimasi: 10 menit'),
          findsOneWidget);
      expect(find.text('SKIP>>'), findsOneWidget);
      expect(find.text('Terima Order Belanja'), findsOneWidget);

      // Tap Terima Order Belanja -> Menuju Konfirmasi PIN Kasir Toko
      await tester.tap(find.text('Terima Order Belanja'));
      await tester.pumpAndSettle();

      // Verifikasi Layar konfirmasi kode toko.png
      expect(find.text('TUNJUKKAN / SEBUTKAN PIN KE KASIR TOKO'),
          findsOneWidget);
      expect(find.text('4 0 9 2'), findsOneWidget);
      expect(find.text('Kasir wajib memasukkan 4 angka ini sebelum diserahkan.'),
          findsOneWidget);
      expect(find.text('2x Nasi Goreng Spesial (1 pedas, 1 tidak)'),
          findsOneWidget);
      expect(find.text('1x Nasi Goreng telur (pedas )'), findsOneWidget);
      expect(find.text('ID : I2E4S68'), findsOneWidget);
      expect(
          find.text('Kasir Sudah Verifikasi PIN & Makanan Diterima'),
          findsOneWidget);
    });

    testWidgets(
        'Complete food flow from PIN confirmation to Delivery and Completion Dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarFlexFoodScreen(
            enableRadarAnimation: false,
            initialOrderState: FlexFoodOrderState.pickupPin,
          ),
        ),
      );

      // Verifikasi PIN Toko
      expect(find.text('4 0 9 2'), findsOneWidget);

      // Tap Kasir Sudah Verifikasi PIN & Makanan Diterima
      await tester.tap(find.text('Kasir Sudah Verifikasi PIN & Makanan Diterima'));
      await tester.pumpAndSettle();

      // Verifikasi Layar Pengantaran (pengataran.png)
      expect(find.text('Lokasi pengataran'), findsOneWidget);
      expect(find.text('Jl. Dumai, ARUN No. 101 (Fikri)'), findsOneWidget);
      expect(
        find.text(
            'Setelah Customer mengkonfirmasi pesanan di terima otomatis bali ke radar.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.phone), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
      expect(find.text('SELESAIKAN PENGANTARAN'), findsOneWidget);

      // Tap Selesaikan Pengantaran -> Muncul Dialog Penyelesaian (iPhone 14 & 15 Pro - 20.png)
      await tester.tap(find.text('SELESAIKAN PENGANTARAN'));
      await tester.pumpAndSettle();

      expect(find.text('Selesaikan Orderan'), findsOneWidget);
      expect(
        find.text(
            'Barang telah diantarkan dengan selamat, tekan tombol selesai untuk kembali keradar dan mencari orderan baru.'),
        findsOneWidget,
      );
      expect(find.text('#I2E4S67'), findsOneWidget);
      expect(find.text('5 Okt 2026 13:02 WIB'), findsOneWidget);
      expect(find.text('Rp 183.000'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      // Tap Selesai -> Dialog tertutup, kembali ke searching
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);
      expect(find.text('Radar'), findsOneWidget);
    });
  });
}
