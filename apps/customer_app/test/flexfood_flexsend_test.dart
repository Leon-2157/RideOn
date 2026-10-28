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
      expect(find.text('Pilihan Terlaris'), findsOneWidget);
      expect(find.text('Bakso Urat'), findsOneWidget);
      expect(find.text('Nasi Goreng'), findsOneWidget);

      // Tap on food item to enter Restaurant
      await tester.tap(find.text('Nasi Goreng'));
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
      expect(find.textContaining('Konfirmasi Pesanan'), findsOneWidget);

      // Confirm order from sheet -> transitions to Checkout
      await tester.tap(find.textContaining('Konfirmasi Pesanan'));
      await tester.pumpAndSettle();

      // 4. Checkout Screen
      expect(find.text('Diantar ke: Rumah (Jl. Brawl No. 77)'), findsOneWidget);
      expect(find.text('Dapur Banku City'), findsOneWidget);
      expect(find.text('Saldo E-Wallet (Rp 185.000)'), findsOneWidget);
      expect(find.text('Rincian Pembayaran'), findsOneWidget);
      expect(find.textContaining('Pesan Makanan Sekarang'), findsOneWidget);

      // Tap Pesan Makanan Sekarang -> transitions to Tracking
      await tester.tap(find.textContaining('Pesan Makanan Sekarang'));
      await tester.pumpAndSettle();

      // 5. Tracking Screen
      expect(find.text('Driver Menuju Restoran...'), findsOneWidget);
      expect(find.text('Muhammad Luthfi Fadil'), findsOneWidget);
      expect(find.text('BK 789 M'), findsOneWidget);
      expect(find.text('HUBUNGI DRIVER'), findsOneWidget);
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
          home: FlexSendScreen(),
        ),
      );

      // 1. Form Screen
      expect(find.text('FlexSend'), findsOneWidget);
      expect(find.text('Titip Belanja Manual'), findsOneWidget);
      expect(find.text('Driver Talangi Dulu di Tempat'), findsOneWidget);
      expect(find.text('Lokasi 1 (Pasar Utama)'), findsOneWidget);
      expect(find.text('Daging Sapi (1 kg)'), findsOneWidget);
      expect(find.text('Lokasi 2 (+Rp 2.000 Ongkir)'), findsOneWidget);
      expect(find.text('Rincian Estimasi Biaya'), findsOneWidget);
      expect(find.text('Cari Driver Belanja'), findsOneWidget);

      // 2. Open Add Item Sheet
      await tester.tap(find.byKey(const Key('btn_add_item_loc_1')));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Barang Belanjaan'), findsOneWidget);
      expect(find.text('Simpan ke Daftar Belanja'), findsOneWidget);

      // Close modal
      await tester.tap(find.byKey(const Key('close_add_item')));
      await tester.pumpAndSettle();

      // 3. Search Driver Flow (cari driver.png)
      await tester.tap(find.byKey(const Key('btn_cari_driver_belanja')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Mencari Driver...'), findsOneWidget);
      expect(find.text('BATALKAN PEMESANAN'), findsOneWidget);

      // Advance to Driver Found (dapat driver.png)
      await tester.tap(find.text('Mencari Driver...'));
      await tester.pumpAndSettle();

      expect(find.text('Driver ditemukan!'), findsOneWidget);
      expect(find.text('Pikri Haykal'), findsOneWidget);
      expect(find.text('BG 4563 R'), findsOneWidget);
      expect(find.text('Lanjut dengan driver ini?'), findsOneWidget);

      // Advance to Shopping (beli brng.png)
      await tester.tap(find.byKey(const Key('btn_lanjut_driver_ini')));
      await tester.pumpAndSettle();

      expect(find.text('Driver Sedang Membelanjakan Barang'), findsOneWidget);
      expect(find.text('Di Pasar Pagi Batuphat (Lokasi 1 dari 2)'), findsOneWidget);

      // Advance to Delivering (driver sampai.png)
      await tester.tap(find.byKey(const Key('banner_sedang_belanja')));
      await tester.pumpAndSettle();

      expect(find.text('Belanja selesai, menuju rumah anda!'), findsOneWidget);
      expect(find.text('Estimasi tiba: 8-12 menit (Jarak 2.1 km)'), findsOneWidget);

      // Advance to Arrived (driver sampai-1.png)
      await tester.tap(find.byKey(const Key('banner_menuju_rumah')));
      await tester.pumpAndSettle();

      expect(find.text('Driver telah sampai'), findsOneWidget);
      expect(find.text('Selesai dan Lihat Rincian Belanja'), findsOneWidget);

      // Advance to Receipt (flrxsend-2.png)
      await tester.tap(find.byKey(const Key('btn_selesai_lihat_rincian')));
      await tester.pumpAndSettle();

      expect(find.text('PEMBAYARAN BERHASIL (LUNAS)'), findsOneWidget);
      expect(find.text('KOMPONEN A'), findsOneWidget);
      expect(find.text('Talangan Riil Driver (Wajib Diganti)'), findsOneWidget);
      expect(find.text('KOMPONEN B'), findsOneWidget);
      expect(find.text('Ongkos Kirim Aplikasi'), findsOneWidget);
      expect(find.text('TOTAL PELUNASAN'), findsOneWidget);
      expect(find.text('Rp 317.000'), findsOneWidget);
      expect(find.text('SELESAI'), findsOneWidget);
    });
  });
}
