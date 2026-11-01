import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/screens/radar/radar_flex_send_screen.dart';
import 'package:driver_app/screens/chat/call_screen.dart';
import 'package:driver_app/screens/chat/chat_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Halaman Radar & Dashboard FlexSend Driver Tests (Figma Spesifikasi)', () {
    testWidgets(
        'RadarFlexSendScreen renders dashboard with driver header, switch, proteksi talangan, and bottom navbar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarFlexSendScreen(
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

      // Verifikasi Card Proteksi Talangan
      expect(find.text('PROTEKSI TALANGAN'), findsOneWidget);
      expect(find.text('Modal Kas Belanja Hari Ini'), findsOneWidget);
      expect(find.text('Rp 200.000'), findsOneWidget);
      expect(
        find.text(
            'Sistem hanya akan memberi order titip belanja dengan total nota kas belanja anda. Tidak dipaksa menalangi lebih.'),
        findsOneWidget,
      );
      expect(find.text('Atur Batas Modal Kas Belanja ->'), findsOneWidget);

      // Verifikasi Card Pendapatan Bersih
      expect(find.text('Pendapatan Bersih Hari Ini'), findsOneWidget);
      expect(find.text('5 Okt 2026'), findsOneWidget);
      expect(find.text('Rp 0'), findsOneWidget);
      expect(find.text('Belum ada trip hari ini'), findsOneWidget);
      expect(find.text('Trip Selesai: 0 Order'), findsOneWidget);

      // Verifikasi Tombol Buka Radar Maps
      expect(find.text('Buka radar maps sekarang'), findsOneWidget);

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
          home: RadarFlexSendScreen(
            enableRadarAnimation: false,
          ),
        ),
      );

      expect(find.text('Status: Online'), findsOneWidget);
      expect(find.text('Buka radar maps sekarang'), findsOneWidget);

      // Toggle ke Offline
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Status: OFFLINE (Istirahat)'), findsOneWidget);
      expect(find.text('Geser tombol untuk mulai cari order'), findsOneWidget);
      // Tombol Buka Radar maps tidak ditampilkan saat offline
      expect(find.text('Buka radar maps sekarang'), findsNothing);

      // Toggle kembali ke Online
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Status: Online'), findsOneWidget);
      expect(find.text('Buka radar maps sekarang'), findsOneWidget);
    });

    testWidgets('Tapping Atur Batas Modal Kas Belanja opens bottom sheet and saves value',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarFlexSendScreen(
            enableRadarAnimation: false,
          ),
        ),
      );

      // Tap Atur Batas Modal Kas Belanja ->
      await tester.tap(find.text('Atur Batas Modal Kas Belanja ->'));
      await tester.pumpAndSettle();

      // Verifikasi Bottom Sheet
      expect(find.text('ATUR MODAL KAS'), findsOneWidget);
      expect(
        find.text(
            'Berapa uang tunai yang Anda bawa di saku hari ini untuk membelanjakan titipan customer ?'),
        findsOneWidget,
      );
      expect(find.text('Rp 300.000 (Maks)'), findsOneWidget);
      expect(find.text('Simpan & Terapkan ke Radar'), findsOneWidget);

      // Pilih Rp 300.000 (Maks)
      await tester.tap(find.text('Rp 300.000 (Maks)'));
      await tester.pumpAndSettle();

      // Simpan & Terapkan ke Radar
      await tester.tap(find.text('Simpan & Terapkan ke Radar'));
      await tester.pumpAndSettle();

      // Verifikasi nilai baru terupdate di dashboard
      expect(find.text('Rp 300.000'), findsOneWidget);
    });

    testWidgets(
        'Tapping Buka radar maps sekarang switches to radar mode and displays searching pill and busy area',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarFlexSendScreen(
            enableRadarAnimation: false,
            initialOrderState: FlexSendOrderState.radarSearching,
          ),
        ),
      );

      // Verifikasi Elemen Radar
      expect(find.text('Area sibuk'), findsOneWidget);
      expect(find.text('Mencari orderan terbaik...'), findsOneWidget);

      // Tapping searching pill simulates incoming order
      await tester.tap(find.text('Mencari orderan terbaik...'));
      await tester.pumpAndSettle();

      // Verifikasi Modal Orderan Masuk
      expect(find.text('ORDERAN BARU MASUK!'), findsOneWidget);
      expect(find.text('TITIP BELANJA'), findsOneWidget);
      expect(find.text('Rp 15.000'), findsOneWidget);
      expect(find.text('Rp 180.000'), findsOneWidget);
      expect(find.text('Pajak batuphat (4 Item)'), findsOneWidget);
      expect(find.text('SKIP>>'), findsOneWidget);
      expect(find.text('Terima Order Belanja'), findsOneWidget);
    });

    testWidgets(
        'Full FlexSend Order Flow: Incoming -> Shopping Checklist -> Input Nota -> Konfirmasi -> Delivering -> Completion',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarFlexSendScreen(
            enableRadarAnimation: false,
            initialOrderState: FlexSendOrderState.incoming,
          ),
        ),
      );

      // 1. Verifikasi Modal Orderan Baru Masuk
      expect(find.text('ORDERAN BARU MASUK!'), findsOneWidget);
      expect(find.text('TITIP BELANJA'), findsOneWidget);

      // 2. Terima Order Belanja -> Menuju Shopping Checklist (iPhone 14 & 15 Pro - 9)
      await tester.tap(find.text('Terima Order Belanja'));
      await tester.pumpAndSettle();

      expect(find.text('Pesanan'), findsOneWidget);
      expect(find.text('Pemesan: Gufran'), findsOneWidget);
      expect(find.text('Lokasi 1: Pasar Pagi Batuphat'), findsOneWidget);
      expect(find.text('Daging Sapi (1 kg)'), findsOneWidget);
      expect(find.text('Rp 120.000'), findsOneWidget);
      expect(find.text('Selesai Belanja > Masukkan Nota & Parkir'), findsOneWidget);

      // Pindah ke Lokasi 2 via Arrow Icon
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('Lokasi 2: Apotik Dien Farma'), findsOneWidget);
      expect(find.text('Paracetamol (1 Papan)'), findsOneWidget);
      expect(find.text('Rp 10.000'), findsOneWidget);

      // 3. Selesai Belanja -> Menuju Input Nota Belanja & Parkir (iPhone 14 & 15 Pro - 16)
      await tester.tap(find.text('Selesai Belanja > Masukkan Nota & Parkir'));
      await tester.pumpAndSettle();

      expect(find.text('Input Nota Belanja & Parkir'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Rp 166.000'), findsOneWidget);
      expect(find.text('Total Retribusi Parkir'), findsOneWidget);
      expect(find.text('+ Rp 15.000'), findsOneWidget);
      expect(find.text('Rp 183.000'), findsOneWidget);
      expect(find.text('Lanjut Antar ke Customer'), findsOneWidget);

      // 4. Lanjut Antar ke Customer -> Muncul Modal Konfirmasi Belanja (iPhone 14 & 15 Pro - 17)
      await tester.tap(find.text('Lanjut Antar ke Customer'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Belanja'), findsOneWidget);
      expect(find.text('Menyerahkan uang cash'), findsOneWidget);
      expect(find.text('ID : I2E4S67'), findsOneWidget);
      expect(
        find.text('klik untuk langsung diarahkan ke maps\nlokasi pengataran'),
        findsOneWidget,
      );

      // 5. Tap ke maps pengataran -> Menuju mode Delivering di peta (iPhone 14 & 15 Pro - 18)
      await tester.tap(
          find.text('klik untuk langsung diarahkan ke maps\nlokasi pengataran'));
      await tester.pumpAndSettle();

      expect(find.text('Pajak batuphat (4 Item)'), findsOneWidget);
      expect(find.text('Jl. Lauser, PIM No. 88 (Gufran)'), findsOneWidget);
      expect(find.text('SELESAIKAN PENGANTARAN'), findsOneWidget);

      // 6. Selesaikan Pengantaran -> Muncul Dialog Penyelesaian (iPhone 14 & 15 Pro - 19)
      await tester.tap(find.text('SELESAIKAN PENGANTARAN'));
      await tester.pumpAndSettle();

      expect(find.text('Selesaikan Orderan'), findsOneWidget);
      expect(find.text('#I2E4S67'), findsOneWidget);
      expect(find.text('5 Okt 2026 13:02 WIB'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      // 7. Selesai -> Kembali ke dashboard
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('PROTEKSI TALANGAN'), findsOneWidget);
      expect(find.text('Modal Kas Belanja Hari Ini'), findsOneWidget);
    });

    testWidgets(
        'RadarFlexSendScreen: Tombol panggilan membuka CallScreen & tombol chat membuka ChatDetailScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: RadarFlexSendScreen(
            enableRadarAnimation: false,
            initialOrderState: FlexSendOrderState.shoppingChecklist,
          ),
        ),
      );

      // Verifikasi tombol call & chat badge tersedia di header checklist
      expect(find.byKey(const Key('btn_call_Gufran')), findsOneWidget);
      expect(find.byKey(const Key('btn_chat_Gufran')), findsOneWidget);

      // 1. Tapping tombol call -> Membuka CallScreen (panggilan), BUKAN Chat
      await tester.tap(find.byKey(const Key('btn_call_Gufran')));
      await tester.pumpAndSettle();

      expect(find.byType(CallScreen), findsOneWidget);
      expect(find.byType(ChatDetailScreen), findsNothing);
      expect(find.text('Gufran'), findsOneWidget);

      // Tutup panggilan via back button
      await tester.tap(find.byKey(const Key('btn_call_back')));
      await tester.pumpAndSettle();

      expect(find.byType(CallScreen), findsNothing);
      expect(find.byType(RadarFlexSendScreen), findsOneWidget);

      // 2. Tapping tombol chat -> Membuka ChatDetailScreen
      await tester.tap(find.byKey(const Key('btn_chat_Gufran')));
      await tester.pumpAndSettle();

      expect(find.byType(ChatDetailScreen), findsOneWidget);
      expect(find.byType(CallScreen), findsNothing);
    });
  });
}
