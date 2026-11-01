import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:driver_app/constants/app_colors.dart';
import 'package:driver_app/services/image_picker_service.dart';
import 'package:driver_app/screens/wallet/wallet_screen.dart';
import 'package:driver_app/screens/wallet/withdraw_screen.dart';
import 'package:driver_app/screens/wallet/claim_talangan_screen.dart';
import 'package:driver_app/screens/wallet/claim_donation_screen.dart';

class FakeImagePickerService extends ImagePickerService {
  final Uint8List fakeBytes;

  FakeImagePickerService({Uint8List? bytes})
      : fakeBytes = bytes ??
            Uint8List.fromList([
              0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
              0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
              0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
              0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
              0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
              0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
              0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
              0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
              0x42, 0x60, 0x82,
            ]);

  @override
  Future<XFile?> pickImageFromCamera({
    double maxWidth = 1920,
    double maxHeight = 1920,
    int imageQuality = 85,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    return XFile.fromData(fakeBytes, path: 'camera_mock_item.png');
  }

  @override
  Future<XFile?> pickImageFromGallery({
    double maxWidth = 1920,
    double maxHeight = 1920,
    int imageQuality = 85,
  }) async {
    return XFile.fromData(fakeBytes, path: 'gallery_mock_receipt.png');
  }

  @override
  Future<Uint8List?> readBytes(XFile file) async {
    return fakeBytes;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Halaman Dompet Driver Tests (Figma Spesifikasi)', () {
    testWidgets('WalletScreen renders balance, stats, transactions, claim banner, and bottom navbar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WalletScreen(),
        ),
      );

      // Verifikasi Header
      expect(find.text('Dompet Driver'), findsOneWidget);

      // Verifikasi Kartu Saldo Aktif
      expect(find.text('Saldo Aktif'), findsOneWidget);
      expect(find.text('Rp 327.000'), findsOneWidget);
      expect(find.text('Pendapatan Ongkir'), findsOneWidget);
      expect(find.text('Rp 45.000'), findsOneWidget);
      expect(find.text('Refund Talangan'), findsOneWidget);
      expect(find.text('Rp 50.000'), findsOneWidget);
      expect(find.text('Tarik Uang Anda'), findsOneWidget);

      // Verifikasi Kartu Transaksi Online
      expect(find.text('Transaksi online'), findsOneWidget);
      expect(find.text('Fee admin'), findsNWidgets(3));
      expect(find.text('Ongkos Kirim'), findsNWidgets(2));
      expect(find.text('- Rp3.500'), findsOneWidget);
      expect(find.text('+ Rp 35.000'), findsOneWidget);
      expect(find.text('- Rp 1.500'), findsNWidgets(2));
      expect(find.text('+ Rp 15.000'), findsOneWidget);

      // Verifikasi Banner Klaim
      expect(find.text('Customer Batalkan/Penipuan Belanjaan?'), findsOneWidget);
      expect(find.text('Ajukan klaim ganti rugi 100%'), findsOneWidget);
      expect(find.text('Klaim Dana '), findsOneWidget);

      // Verifikasi Bottom Navbar
      expect(find.text('Radar'), findsOneWidget);
      expect(find.text('Aktivitas'), findsOneWidget);
      expect(find.text('Dompet'), findsOneWidget);
      expect(find.text('chat'), findsOneWidget);
    });

    testWidgets('Tapping Tarik Uang Anda navigates to WithdrawScreen and handles withdrawal flow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WalletScreen(),
        ),
      );

      await tester.tap(find.text('Tarik Uang Anda'));
      await tester.pumpAndSettle();

      // Memastikan berada di Layar Tarik Saldo
      expect(find.byType(WithdrawScreen), findsOneWidget);
      expect(find.text('Tarik Saldo'), findsOneWidget);
      expect(find.text('Bank Syariah Indonesia (BSI)'), findsOneWidget);
      expect(find.text('8820-1928-34 a.n Joni Utama'), findsOneWidget);
      expect(find.text('Tarik Semua'), findsOneWidget);

      // Cek nominal chips
      expect(find.text('Rp 1000.000'), findsOneWidget);
      expect(find.text('Rp 500.000'), findsOneWidget);
      expect(find.text('Rp 250.000'), findsOneWidget);

      // Cek biaya & estimasi
      expect(find.text('Biaya Layanan Penarikan'), findsOneWidget);
      expect(find.text('Rp 2.000'), findsOneWidget);
      expect(find.text('Instan (15 Menit)'), findsOneWidget);

      // Tekan tombol Tarik Semua
      await tester.tap(find.text('Tarik Semua'));
      await tester.pumpAndSettle();

      // Tombol berubah menjadi "Konfirmasi & Masukkan PIN"
      expect(find.text('Konfirmasi & Masukkan PIN'), findsOneWidget);

      // Tekan Konfirmasi & Masukkan PIN
      await tester.tap(find.text('Konfirmasi & Masukkan PIN'));
      await tester.pumpAndSettle();

      // Dialog PIN muncul
      expect(find.text('Masukkan Sandi Anda'), findsOneWidget);
      expect(find.text('KIRIM'), findsOneWidget);

      // Kirim PIN
      await tester.tap(find.text('KIRIM'));
      await tester.pumpAndSettle();

      // Dialog Sukses muncul
      expect(find.text('Pengajuan Tarik Saldo Berhasil!'), findsOneWidget);
      expect(find.text('#99401'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      // Tekan selesai untuk kembali ke WalletScreen
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.byType(WalletScreen), findsOneWidget);
    });

    testWidgets('WithdrawScreen invokes native phone keyboard and handles input correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WithdrawScreen(),
        ),
      );

      // Pastikan TextField tersedia dengan keyboardType TextInputType.number
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final TextField textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.keyboardType, TextInputType.number);

      // Pastikan tombol keypad kustom tidak ada lagi di layar
      expect(find.text('A B C'), findsNothing);
      expect(find.text('D E F'), findsNothing);

      // Verifikasi awal button teks Masukan Nominal
      expect(find.text('Masukan Nominal'), findsOneWidget);

      // Mengetuk tombol Masukan Nominal memicu fokus ke TextField (memanggil keyboard hp)
      await tester.tap(find.text('Masukan Nominal'));
      await tester.pumpAndSettle();
      expect(textField.focusNode?.hasFocus, isTrue);

      // Masukkan nominal lewat keyboard HP native
      await tester.enterText(textFieldFinder, '200000');
      await tester.pumpAndSettle();

      // Tombol berubah menjadi Konfirmasi & Masukkan PIN
      expect(find.text('Konfirmasi & Masukkan PIN'), findsOneWidget);

      // Mengetuk chip nominal Rp 500.000 memperbarui teks controller
      await tester.tap(find.text('Rp 500.000'));
      await tester.pumpAndSettle();
      expect(find.text('500000'), findsOneWidget);

      // Submit via keyboard action Done membuka dialog PIN
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Masukkan Sandi Anda'), findsOneWidget);
    });

    testWidgets('Tapping Klaim Dana navigates to ClaimTalanganScreen and complete donation flow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WalletScreen(),
        ),
      );

      // Tap Klaim Dana
      await tester.tap(find.text('Klaim Dana '));
      await tester.pumpAndSettle();

      // Verifikasi Layar Klaim Uang Talangan Belanja
      expect(find.byType(ClaimTalanganScreen), findsOneWidget);
      expect(find.text('Klaim Uang Talangan Belanja'), findsOneWidget);
      expect(find.text('Jaminan Proteksi Talangan 100%'), findsOneWidget);
      expect(find.text('ID : I2E4S69'), findsOneWidget);
      expect(find.text('Pikri (Batal Sepihak)'), findsOneWidget);
      expect(find.text('Rp 177.000 (Nota+Parkir)'), findsOneWidget);
      expect(find.text('Foto Barang Belanjaan Fisik'), findsOneWidget);
      expect(find.text('Foto Nota Asli Lapak & Karcis'), findsOneWidget);
      expect(find.text('Alasan Pembatalan di Lapangan'), findsOneWidget);

      // Tap Selanjutnya ke Step 2 Donasi
      await tester.tap(find.text('SELANJUTNYA'));
      await tester.pumpAndSettle();

      // Verifikasi Layar Donasi Panti Asuhan
      expect(find.byType(ClaimDonationScreen), findsOneWidget);
      expect(find.text('Donasi belanjaan ke panti asuhan'), findsOneWidget);
      expect(find.text('Pemberian  kepanti asuhan yang membutuhkan'), findsOneWidget);
      expect(find.text('Panti Asuhan Terdekat'), findsOneWidget);
      expect(find.text('Foto Penyerahan Barang'), findsOneWidget);
      expect(find.text('Keteranagn pemberian donasi'), findsOneWidget);

      // Tap Kirim Klaim Anti Rugi Sekarang
      await tester.tap(find.text('Kirim klaim anti rugi sekarang'));
      await tester.pumpAndSettle();

      // Dialog Persetujuan Klaim Muncul
      expect(find.text('Klaim talangan anda di setujui'), findsOneWidget);
      expect(find.text('Saldo Dompet Anda'), findsOneWidget);
      expect(find.text('Tarik Saldo'), findsOneWidget);
      expect(find.text('Kembali ke radar kerja'), findsOneWidget);

      final dialogFinder = find.byType(Dialog);
      expect(dialogFinder, findsOneWidget);
      final dialogWidget = tester.widget<Dialog>(dialogFinder);
      expect(dialogWidget.backgroundColor, equals(AppColors.white));
      expect(dialogWidget.surfaceTintColor, equals(Colors.transparent));
    });

    testWidgets('Tapping transaction item opens Rincian Transaksi modal and closes cleanly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WalletScreen(),
        ),
      );

      // Tap Ongkos Kirim transaksi pertama
      await tester.tap(find.text('+ Rp 35.000'));
      await tester.pumpAndSettle();

      // Verifikasi Rincian Transaksi Bottom Sheet muncul
      expect(find.text('Rincian Transaksi'), findsOneWidget);
      expect(find.text('Berhasil'), findsOneWidget);
      expect(find.text('Layanan Terkait'), findsOneWidget);
      expect(find.text('Tutup Rincian'), findsOneWidget);

      // Tutup Rincian
      await tester.tap(find.text('Tutup Rincian'));
      await tester.pumpAndSettle();

      expect(find.text('Rincian Transaksi'), findsNothing);
    });

    testWidgets('Top up flow adds balance and records transaction',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WalletScreen(),
        ),
      );

      // Tap Top Up Saldo
      await tester.tap(find.text('Top Up Saldo'));
      await tester.pumpAndSettle();

      // Verifikasi Modal Top Up muncul
      expect(find.text('Isi Saldo Dompet Driver'), findsOneWidget);
      expect(find.text('Konfirmasi Top Up'), findsOneWidget);

      // Konfirmasi Top Up (default Rp 50.000)
      await tester.tap(find.text('Konfirmasi Top Up'));
      await tester.pumpAndSettle();

      // Saldo bertambah dari 327.000 + 50.000 = 377.000
      expect(find.text('Rp 377.000'), findsOneWidget);
      expect(find.text('Top Up Saldo Driver'), findsOneWidget);
    });

    testWidgets('Filter transactions updates list correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WalletScreen(),
        ),
      );

      // Tap Filter Pendapatan
      await tester.tap(find.text('Pendapatan'));
      await tester.pumpAndSettle();

      // Hanya menampilkan item pendapatan (kredit hijau)
      expect(find.text('+ Rp 35.000'), findsOneWidget);
      expect(find.text('+ Rp 15.000'), findsOneWidget);
      expect(find.text('- Rp3.500'), findsNothing);

      // Tap Filter Biaya Admin
      await tester.tap(find.text('Biaya Admin'));
      await tester.pumpAndSettle();

      expect(find.text('- Rp3.500'), findsOneWidget);
      expect(find.text('+ Rp 35.000'), findsNothing);
    });

    testWidgets(
        'ClaimTalanganScreen photo picker sheet opens, cancels, and supports camera/gallery picking',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakePicker = FakeImagePickerService();

      await tester.pumpWidget(
        MaterialApp(
          home: ClaimTalanganScreen(
            initialItemPhotoUploaded: false,
            initialReceiptPhotoUploaded: false,
            imagePickerService: fakePicker,
          ),
        ),
      );

      // Status awal: badge menampilkan JPG/PNG dan PNG/JPG
      expect(find.text('JPG/PNG'), findsOneWidget);
      expect(find.text('PNG/JPG'), findsOneWidget);

      // Ketuk kotak Foto Barang Belanjaan Fisik
      await tester.tap(find.byKey(const Key('btn_upload_item_photo')));
      await tester.pumpAndSettle();

      // Verifikasi bottom sheet modal muncul sesuai screenshot & Figma
      expect(find.text('Pilih Foto Belanjaan & Nota'), findsOneWidget);
      expect(find.text('Ambil Foto'), findsOneWidget);
      expect(find.text('Buka Kamera dan Ambil Foto'), findsOneWidget);
      expect(find.text('Pilih Dari Galeri'), findsOneWidget);
      expect(find.text('Pilih Foto Dari Perangkat'), findsOneWidget);
      expect(find.text('BATAL'), findsOneWidget);

      // Ketuk BATAL
      await tester.tap(find.byKey(const Key('btn_batal_picker')));
      await tester.pumpAndSettle();

      // Bottom sheet tertutup
      expect(find.text('Pilih Foto Belanjaan & Nota'), findsNothing);

      // Buka kembali dan pilih Ambil Foto (Kamera)
      await tester.tap(find.byKey(const Key('btn_upload_item_photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opt_ambil_foto')));
      await tester.pumpAndSettle();

      // Foto barang berhasil diupload dan status menjadi Terupload
      expect(find.text('Terupload'), findsOneWidget);
      expect(find.text('Foto barang belanjaan berhasil dipilih'), findsOneWidget);

      // Buka kotak Foto Nota Asli Lapak & Karcis dan pilih Pilih Dari Galeri
      await tester.tap(find.byKey(const Key('btn_upload_receipt_photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opt_pilih_galeri')));
      await tester.pumpAndSettle();

      // Keduanya sekarang berstatus Terupload
      expect(find.text('Terupload'), findsNWidgets(2));
      expect(find.text('Foto nota belanja berhasil dipilih'), findsOneWidget);
    });

    testWidgets(
        'ClaimDonationScreen photo picker sheet opens, cancels, and supports camera/gallery picking',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakePicker = FakeImagePickerService();

      await tester.pumpWidget(
        MaterialApp(
          home: ClaimDonationScreen(
            initialPhotoUploaded: false,
            imagePickerService: fakePicker,
          ),
        ),
      );

      // Status awal: badge JPG/PNG
      expect(find.text('JPG/PNG'), findsOneWidget);

      // Ketuk kotak Foto Penyerahan Barang
      await tester.tap(find.byKey(const Key('btn_upload_donation_photo')));
      await tester.pumpAndSettle();

      // Verifikasi bottom sheet modal muncul
      expect(find.text('Pilih Foto Penyerahan Barang'), findsOneWidget);
      expect(find.text('Ambil Foto'), findsOneWidget);
      expect(find.text('Pilih Dari Galeri'), findsOneWidget);
      expect(find.text('BATAL'), findsOneWidget);

      // Ketuk BATAL
      await tester.tap(find.byKey(const Key('btn_batal_picker_donation')));
      await tester.pumpAndSettle();
      expect(find.text('Pilih Foto Penyerahan Barang'), findsNothing);

      // Buka kembali dan pilih Ambil Foto
      await tester.tap(find.byKey(const Key('btn_upload_donation_photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('opt_ambil_foto_donation')));
      await tester.pumpAndSettle();

      // Foto terupload
      expect(find.text('Terupload'), findsOneWidget);
      expect(find.text('Foto penyerahan barang berhasil dipilih'), findsOneWidget);
    });

    testWidgets('Top notification banner renders at the top with title, message, and icon on withdraw or top-up',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: WalletScreen(),
        ),
      );

      // Tap Top Up Saldo
      await tester.tap(find.text('Top Up Saldo'));
      await tester.pumpAndSettle();

      // Tap Konfirmasi Top Up
      await tester.tap(find.text('Konfirmasi Top Up'));
      await tester.pumpAndSettle();

      // Verifikasi top notification muncul di atas layar
      expect(find.text('Top Up Berhasil'), findsOneWidget);
      expect(find.text('Top Up Rp 50.000 berhasil ditambahkan ke saldo aktif!'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Verifikasi letak notifikasi berada di bagian atas layar
      final topNotificationFinder = find.text('Top Up Berhasil');
      final Offset position = tester.getTopLeft(topNotificationFinder);
      expect(position.dy < 200, isTrue);
      expect(position.dy >= 0, isTrue);

      // Ketuk tombol close untuk dismiss
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Top Up Berhasil'), findsNothing);
    });
  });
}
