import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideon/features/flexfood/presentation/pages/flexfood_screen.dart';
import 'package:rideon/features/flexsend/presentation/pages/flexsend_screen.dart';

void main() {
  group('FlexFoodScreen Tests', () {
    testWidgets('FlexFoodScreen renders grid and transitions through restaurant, sheet, checkout, and tracking', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: FlexFoodScreen(),
        ),
      );

      // 1. Grid Screen
      expect(find.text('FlexFood'), findsOneWidget);
      expect(find.text('Paling Laris Minggu Ini'), findsOneWidget);
      expect(find.text('Bakso Urat'), findsOneWidget);

      // Tap on restaurant card to enter RestaurantView
      await tester.ensureVisible(find.text('Banku City Resto & Cafe'));
      await tester.tap(find.text('Banku City Resto & Cafe'));
      await tester.pumpAndSettle();

      // 2. Restaurant Screen
      expect(find.text('Banku City'), findsOneWidget);
      expect(find.text('Nasi Goreng Spesial'), findsOneWidget);
      expect(find.text('+Tambah'), findsOneWidget);
      expect(find.text('Lihat Keranjang'), findsOneWidget);

      // Tap +Tambah to open customization sheet
      await tester.tap(find.text('+Tambah'));
      await tester.pumpAndSettle();

      // 3. Customization Sheet
      expect(find.text('Tingkat Kepedasan '), findsOneWidget);
      expect(find.text('Level 3 (Pedas Banget)'), findsOneWidget);
      expect(find.text('Tambahan Topping '), findsOneWidget);
      expect(find.text('Tambah Telur Dadar'), findsOneWidget);
      await tester.tap(find.text('Level 3 (Pedas Banget)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Konfirmasi Pesanan'), findsOneWidget);

      // Confirm order from sheet -> transitions to Checkout
      await tester.tap(find.textContaining('Konfirmasi Pesanan'));
      await tester.pumpAndSettle();

      // 4. Checkout Screen
      expect(find.text('Diantar ke: Rumah (Jl. Brawl No. 77)'), findsOneWidget);
      expect(find.text('Tunai / Cash Langsung'), findsOneWidget);
      expect(find.text('QRIS (Non-Tunai)'), findsOneWidget);
      expect(find.text('Rincian Pembayaran'), findsOneWidget);
      expect(find.textContaining('Pesan Makanan Sekarang'), findsOneWidget);

      // Tap Pesan Makanan Sekarang -> transitions to Tracking
      await tester.tap(find.textContaining('Pesan Makanan Sekarang'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 5. Tracking Screen
      expect(find.text('Driver Menuju Restoran...'), findsOneWidget);
      expect(find.text('Muhammad Luthfi Fadil'), findsOneWidget);
      expect(find.text('BK 789 M'), findsOneWidget);
      expect(find.text('Hubungi Driver'), findsOneWidget);
    });
  });

  group('FlexSendScreen Tests', () {
    testWidgets('FlexSendScreen renders locations, adds items, and searches driver', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: FlexSendScreen(initialEmpty: false),
        ),
      );

      // 1. Form Screen
      expect(find.text('FlexSend'), findsWidgets);
      expect(find.text('Titip Belanja Manual'), findsOneWidget);
      expect(find.text('Driver Talangi Dulu di Tempat'), findsOneWidget);
      expect(find.text('Lokasi 1 (Pasar Utama)'), findsOneWidget);
      expect(find.textContaining('Daging Sapi (1 kg)'), findsOneWidget);
      expect(find.text('Lokasi 2 (+Rp 2.000 Ongkir)'), findsOneWidget);
      expect(find.text('Ongkos Kirim Aplikasi'), findsOneWidget);
      expect(find.text('Cari Driver Belanja'), findsOneWidget);

      // 2. Open Add Item Sheet
      await tester.tap(find.byKey(const Key('btn_add_item_loc_1')));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Barang Belanjaan'), findsOneWidget);
      expect(find.text('Simpan ke Daftar Belanja'), findsOneWidget);

      // Close modal
      await tester.tap(find.byKey(const Key('close_add_item')));
      await tester.pumpAndSettle();

      // 3. Search Driver Flow
      await tester.tap(find.text('Cari Driver Belanja'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Mencari Driver...'), findsOneWidget);
      expect(find.text('BATALKAN PEMESANAN'), findsOneWidget);

      // Advance via auto timer / tap to Driver Found
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();

      expect(find.text('Driver ditemukan!'), findsOneWidget);
      expect(find.text('Pikri Haykal'), findsOneWidget);
      expect(find.text('BG 4563 R'), findsOneWidget);
      expect(find.text('Lanjutkan Pesanan'), findsOneWidget);

      // Advance to Shopping
      await tester.tap(find.byKey(const Key('btn_lanjut_driver_ini')));
      await tester.pumpAndSettle();

      expect(find.text('Driver Sedang Belanja'), findsOneWidget);
      expect(find.text('Di Pasar Pagi Batuphat (Toko 1 dari 2)'), findsOneWidget);

      // Advance via shopping timer (4.5s) to Delivering
      await tester.pump(const Duration(milliseconds: 4600));
      await tester.pumpAndSettle();

      expect(find.text('Driver Menuju Rumah Anda!'), findsOneWidget);

      // Advance via delivering timer (4.5s) to Arrived
      await tester.pump(const Duration(milliseconds: 4600));
      await tester.pumpAndSettle();

      expect(find.text('Driver Telah Sampai!'), findsOneWidget);
      expect(find.text('Lihat Rincian Belanja'), findsOneWidget);

      // Advance to Receipt
      await tester.tap(find.byKey(const Key('btn_selesai_lihat_rincian')));
      await tester.pumpAndSettle();

      expect(find.text('Rincian Belanja'), findsOneWidget);
      expect(find.text('TOTAL RINCIAN BELANJA ASLI'), findsOneWidget);
      expect(find.text('Talangan Riil Driver'), findsOneWidget);
      expect(find.text('TOTAL PELUNASAN'), findsOneWidget);
      expect(find.text('Pembayaran Selesai'), findsOneWidget);
    });
  });
}
