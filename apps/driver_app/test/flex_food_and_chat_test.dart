import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/screens/radar/radar_flex_food_screen.dart';
import 'package:driver_app/screens/chat/call_screen.dart';
import 'package:driver_app/screens/chat/chat_history_screen.dart';
import 'package:driver_app/screens/chat/chat_detail_screen.dart';
import 'package:driver_app/screens/account_settings/account_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Halaman Radar FlexFood Tests (Figma Spesifikasi)', () {
    testWidgets(
        'RadarFlexFoodScreen renders header, map, resto markers, and searching card',
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

      // Verifikasi Switch Status Online
      expect(find.text('Status: Online'), findsOneWidget);
      expect(find.text('Geser tombol untuk off'), findsOneWidget);

      // Verifikasi Area Sibuk & POI Resto
      expect(find.text('Area sibuk'), findsOneWidget);
      expect(find.text('Waroeng Bamboe'), findsOneWidget);

      // Verifikasi Floating Searching Pill
      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);

      // Verifikasi Bottom Navbar (4 Tabs)
      expect(find.text('Radar'), findsOneWidget);
      expect(find.text('Aktivitas'), findsOneWidget);
      expect(find.text('Dompet'), findsOneWidget);
      expect(find.text('chat'), findsOneWidget);
    });

    testWidgets('Toggling switch changes status between Online and Offline',
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

      // Toggle ke Offline
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Status: Offline'), findsOneWidget);
      expect(
        find.text('Anda sedang Offline. Aktifkan status untuk bekerja.'),
        findsOneWidget,
      );

      // Toggle kembali ke Online
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Status: Online'), findsOneWidget);
      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);
    });

    testWidgets(
        'Tapping Driver Profile Pill navigates to AccountSettingsScreen',
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

      await tester.tap(find.text('Joni utama'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountSettingsScreen), findsOneWidget);
    });

    testWidgets(
        'Full FlexFood Order Flow: Incoming -> Store PIN 4092 -> Delivering -> Completion',
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

      // 1. Verifikasi Modal Orderan Masuk (pemesanan makanan.png)
      expect(find.text('ORDERAN BARU MASUK!'), findsOneWidget);
      expect(find.text('PESAN MAKANAN'), findsOneWidget);
      expect(find.text('Rp 15.000'), findsOneWidget);
      expect(find.text('Non-Tunai (E-Wallet)'), findsOneWidget);
      expect(find.text('Jl. Dumai, ARUN No. 101 (Fikri)'), findsOneWidget);
      expect(find.text('SKIP>>'), findsOneWidget);
      expect(find.text('Terima Order Belanja'), findsOneWidget);

      // 2. Terima Order Belanja -> Menuju Konfirmasi PIN Toko (konfirmasi kode toko.png)
      await tester.tap(find.text('Terima Order Belanja'));
      await tester.pumpAndSettle();

      expect(
          find.text('TUNJUKKAN / SEBUTKAN PIN KE KASIR TOKO'), findsOneWidget);
      expect(find.text('4 0 9 2'), findsOneWidget);
      expect(find.text('2x Nasi Goreng Spesial (1 pedas, 1 tidak)'),
          findsOneWidget);
      expect(find.text('ID : I2E4S68'), findsOneWidget);
      expect(find.text('Kasir Sudah Verifikasi PIN & Makanan Diterima'),
          findsOneWidget);

      // 3. Kasir verifikasi PIN -> Menuju Lokasi Pengantaran (pengataran.png)
      await tester.tap(find.text('Kasir Sudah Verifikasi PIN & Makanan Diterima'));
      await tester.pumpAndSettle();

      expect(find.text('Lokasi pengataran'), findsOneWidget);
      expect(
        find.text(
            'Setelah Customer mengkonfirmasi pesanan di terima otomatis bali ke radar.'),
        findsOneWidget,
      );
      expect(find.text('SELESAIKAN PENGANTARAN'), findsOneWidget);

      // 4. Selesaikan Pengantaran -> Menampilkan Dialog Transaksi (iPhone 14 & 15 Pro - 20.png)
      await tester.tap(find.text('SELESAIKAN PENGANTARAN'));
      await tester.pumpAndSettle();

      expect(find.text('Selesaikan Orderan'), findsOneWidget);
      expect(find.text('#I2E4S67'), findsOneWidget);
      expect(find.text('5 Okt 2026 13:02 WIB'), findsOneWidget);
      expect(find.text('Rp 183.000'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      // 5. Tutup dialog penyelesaian -> Kembali ke mode pencarian
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);
    });

    testWidgets('Tapping SKIP on incoming order returns to searching mode',
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

      expect(find.text('SKIP>>'), findsOneWidget);
      await tester.tap(find.text('SKIP>>'));
      await tester.pumpAndSettle();

      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);
    });
  });

  group('Halaman Chat & Panggilan Tests (Figma Spesifikasi)', () {
    testWidgets('ChatHistoryScreen renders conversations and navigates to detail',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ChatHistoryScreen(),
        ),
      );

      // Verifikasi Header Riwayat Chat
      expect(find.text('Riwayat Chat'), findsOneWidget);

      // Verifikasi Daftar Kontak Percakapan
      expect(find.text('M.topik'), findsOneWidget);
      expect(find.text('Panggilan berakhir'), findsOneWidget);
      expect(find.text('Melissa'), findsOneWidget);
      expect(find.text('Anda : Baik'), findsOneWidget);

      // Tap percakapan M.topik -> Masuk ke ChatDetailScreen
      await tester.tap(find.text('M.topik'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatDetailScreen), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Hi bang, saya sudah sesuai titik penjemputan'),
          findsOneWidget);
    });

    testWidgets('ChatDetailScreen allows sending message and triggers call overlay',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ChatDetailScreen(
            customerName: 'M.topik',
          ),
        ),
      );

      // Verifikasi Input Teks & Mengirim Pesan
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);

      await tester.enterText(inputFinder, 'Siap meluncur!');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Siap meluncur!'), findsOneWidget);

      // Verifikasi Membuka Panggilan Telepon (telpon berlangsung.png)
      await tester.tap(find.byIcon(Icons.phone_rounded));
      await tester.pumpAndSettle();

      // Overlay panggilan telepon aktif
      expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);

      // Akhiri Panggilan Telepon
      await tester.tap(find.byIcon(Icons.call_end_rounded));
      await tester.pumpAndSettle();

      // Overlay tertutup
      expect(find.byIcon(Icons.call_end_rounded), findsNothing);
    });

    testWidgets(
        'RadarFlexFoodScreen: Tombol panggilan membuka CallScreen (bukan Chat) & tombol chat membuka ChatDetailScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarFlexFoodScreen(
            enableRadarAnimation: false,
            initialOrderState: FlexFoodOrderState.delivering,
          ),
        ),
      );

      // Verifikasi tombol call & chat ada di layar pengantaran
      expect(find.byKey(const Key('btn_call_customer')), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble), findsOneWidget);

      // 1. Tekan tombol panggilan -> Membuka CallScreen (Panggilan), BUKAN ChatDetailScreen
      await tester.tap(find.byKey(const Key('btn_call_customer')));
      await tester.pumpAndSettle();

      expect(find.byType(CallScreen), findsOneWidget);
      expect(find.byType(ChatDetailScreen), findsNothing);
      expect(find.text('Fikri'), findsOneWidget);
      expect(find.byKey(const Key('btn_end_call')), findsOneWidget);
      expect(find.byKey(const Key('btn_call_speaker')), findsOneWidget);
      expect(find.byKey(const Key('btn_call_mute')), findsOneWidget);

      // Toggle Speaker & Mute
      await tester.tap(find.byKey(const Key('btn_call_speaker')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_call_mute')));
      await tester.pumpAndSettle();

      // Akhiri Panggilan -> Kembali ke layar RadarFlexFoodScreen
      await tester.tap(find.byKey(const Key('btn_end_call')));
      await tester.pumpAndSettle();

      expect(find.byType(CallScreen), findsNothing);
      expect(find.byType(RadarFlexFoodScreen), findsOneWidget);

      // 2. Tekan tombol chat -> Membuka ChatDetailScreen
      await tester.tap(find.byIcon(Icons.chat_bubble));
      await tester.pumpAndSettle();

      expect(find.byType(ChatDetailScreen), findsOneWidget);
      expect(find.byType(CallScreen), findsNothing);
    });
  });
}
