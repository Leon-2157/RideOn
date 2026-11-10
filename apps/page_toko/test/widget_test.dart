import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_toko/data/toko_state.dart';
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
    TokoState.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/image_picker'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'pickImage') {
          return '/mock/path/document.jpg';
        }
        return null;
      },
    );
  });

  testWidgets('TokoApp smoke test starts at login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TokoApp());
    expect(find.byType(TokoApp), findsOneWidget);
    expect(find.byType(TokoLoginScreen), findsOneWidget);
    expect(find.text('MASUK'), findsOneWidget);
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

  testWidgets('Menu renders on 360x640 and opens photo picker sheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoMenuScreen())));
    expect(find.text('Daftar Menu'), findsOneWidget);

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Menu'), findsOneWidget);
    expect(find.byKey(const Key('btn_upload_menu_photo')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_upload_menu_photo')));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Foto Menu'), findsOneWidget);
    expect(find.text('Ambil Dari Kamera'), findsOneWidget);
    expect(find.text('Pilih Dari Galeri'), findsOneWidget);
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

  testWidgets('Login and registration steps validate inputs and render on 360x640', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    bool loggedIn = false;
    await tester.pumpWidget(MaterialApp(home: TokoLoginScreen(onLoginSuccess: () => loggedIn = true)));
    expect(find.text('MASUK'), findsOneWidget);

    // Test empty login validation
    await tester.tap(find.text('MASUK'));
    await tester.pumpAndSettle();
    expect(find.text('Email/WhatsApp dan kata sandi wajib diisi.'), findsOneWidget);

    // Test invalid format
    await tester.enterText(find.byKey(const Key('input_login_identifier')), 'bukan-email-atau-wa');
    await tester.enterText(find.byKey(const Key('input_login_password')), '123');
    await tester.tap(find.text('MASUK'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan email / No. WA valid dan sandi minimal 6 karakter.'), findsOneWidget);

    // Typing resets error
    await tester.enterText(find.byKey(const Key('input_login_identifier')), '08123456789');
    await tester.pump();
    expect(find.text('Masukkan email / No. WA valid dan sandi minimal 6 karakter.'), findsNothing);

    // Test Lupa Kata Sandi validation & flow
    await tester.tap(find.text('Lupa kata sandi?'));
    await tester.pumpAndSettle();
    expect(find.text('Lupa Kata Sandi?'), findsOneWidget);

    await tester.tap(find.text('KIRIM KODE OTP'));
    await tester.pumpAndSettle();
    expect(find.text('Lupa Kata Sandi?'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('input_forgot_identifier')), '08123456789');
    await tester.tap(find.text('KIRIM KODE OTP'));
    await tester.pumpAndSettle();
    expect(find.text('Verifikasi WhatsApp'), findsOneWidget);
    expect(find.text('VERIFIKASI'), findsOneWidget);
    expect(find.text('Kirim Ulang Kode'), findsOneWidget);

    // Tap Verifikasi without 6 digits -> stays on OTP
    await tester.tap(find.text('VERIFIKASI'));
    await tester.pumpAndSettle();
    expect(find.text('Verifikasi WhatsApp'), findsOneWidget);

    // Enter valid 6-digit OTP -> goes to Step 5 (Buat Sandi Baru)
    await tester.enterText(find.byKey(const Key('input_otp_code')), '123456');
    await tester.tap(find.text('VERIFIKASI'));
    await tester.pumpAndSettle();
    expect(find.text('Buat Sandi Baru'), findsOneWidget);

    // Test reset password validation
    await tester.enterText(find.byKey(const Key('input_new_password')), 'pass1');
    await tester.enterText(find.byKey(const Key('input_confirm_password')), 'pass1');
    await tester.tap(find.byKey(const Key('btn_save_new_password')));
    await tester.pumpAndSettle();
    expect(find.text('Buat Sandi Baru'), findsOneWidget);

    // Valid reset password -> returns to login
    await tester.enterText(find.byKey(const Key('input_new_password')), 'password123');
    await tester.enterText(find.byKey(const Key('input_confirm_password')), 'password123');
    await tester.tap(find.byKey(const Key('btn_save_new_password')));
    await tester.pumpAndSettle();
    expect(find.text('MASUK'), findsOneWidget);

    // Tap Daftar Sekarang -> goes to Lengkapi Daftar Toko
    await tester.tap(find.byKey(const Key('link_daftar_sekarang')));
    await tester.pumpAndSettle();
    expect(find.text('Lengkapi Daftar Toko'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('input_reg_store_name')), 'Warung Barokah Baru');
    await tester.enterText(find.byKey(const Key('input_reg_owner_name')), 'Siti Aminah');
    await tester.enterText(find.byKey(const Key('input_reg_address')), 'Jl. Merdeka No. 1');

    // Check Syarat & Ketentuan checkbox
    final checkbox = find.byType(Checkbox);
    await tester.ensureVisible(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    // Tap UPLOAD without documents -> validation fails
    final uploadBtn = find.text('UPLOAD');
    await tester.ensureVisible(uploadBtn);
    await tester.pumpAndSettle();
    await tester.tap(uploadBtn);
    await tester.pumpAndSettle();
    expect(find.text('Unggah minimal 1 foto/berkas verifikasi toko.'), findsOneWidget);
    expect(find.text('Lengkapi Daftar Toko'), findsOneWidget);

    // Upload document 0 via gallery mock
    final uploadDocBtn = find.byKey(const Key('btn_upload_doc_0'));
    await tester.ensureVisible(uploadDocBtn);
    await tester.pumpAndSettle();
    await tester.tap(uploadDocBtn);
    await tester.pumpAndSettle();
    expect(find.text('Pilih Foto'), findsOneWidget);
    await tester.tap(find.text('Pilih Dari Galeri'));
    await tester.pumpAndSettle();
    expect(find.text('Terupload'), findsOneWidget);

    // Tap UPLOAD to Step 4 (Berkas Berhasil di Upload)
    await tester.ensureVisible(uploadBtn);
    await tester.pumpAndSettle();
    await tester.tap(uploadBtn);
    await tester.pumpAndSettle();
    expect(find.text('BERKAS BERHASIL DI UPLOAD'), findsOneWidget);
    expect(find.text('KEMBALI KE HALAMAN MASUK'), findsOneWidget);
    expect(TokoState.storeName.value, 'Warung Barokah Baru');
    expect(TokoState.ownerName.value, 'Siti Aminah');

    // Tap KEMBALI KE HALAMAN MASUK -> returns to login
    await tester.tap(find.text('KEMBALI KE HALAMAN MASUK'));
    await tester.pumpAndSettle();
    expect(find.text('MASUK'), findsOneWidget);

    // Valid login executes callback
    await tester.enterText(find.byKey(const Key('input_login_identifier')), '08123456789');
    await tester.enterText(find.byKey(const Key('input_login_password')), 'password123');
    await tester.tap(find.text('MASUK'));
    await tester.pumpAndSettle();
    expect(loggedIn, isTrue);
  });

  testWidgets('OrderDetailScreen renders dynamic order #FD-8821 and completes order',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoOrdersScreen())));
    expect(find.text('ID Pesanan #FD-8821'), findsOneWidget);

    await tester.tap(find.text('Rincian >').first);
    await tester.pumpAndSettle();

    expect(find.text('Ahmad Fauzi'), findsOneWidget);
    expect(find.text('#FD-8821'), findsOneWidget);
    expect(find.text('Kurir: Joni Utama'), findsOneWidget);

    final finishBtn = find.text('Tandai Pesanan Selesai');
    await tester.ensureVisible(finishBtn);
    await tester.pumpAndSettle();
    await tester.tap(finishBtn);
    await tester.pumpAndSettle();

    expect(find.text('Selesai (1)'), findsOneWidget);
    expect(find.text('Diproses (2)'), findsOneWidget);
  });

  testWidgets('Home order action rejects and updates TokoState', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoHomeScreen())));
    expect(find.text('Pesanan Perlu Diproses (1)'), findsOneWidget);

    final rejectBtn = find.text('Tolak');
    await tester.ensureVisible(rejectBtn);
    await tester.pumpAndSettle();
    await tester.tap(rejectBtn);
    await tester.pumpAndSettle();

    expect(find.text('Pesanan Perlu Diproses (0)'), findsOneWidget);
    expect(find.text('Semua pesanan telah diproses'), findsOneWidget);
  });

  testWidgets('Finance PIN cancel preserves balance and valid PIN deducts with history',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoFinanceScreen())));
    expect(find.text('Rp 12.450.000'), findsOneWidget);

    await tester.tap(find.text('Tarik Saldo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konfirmasi & Masukkan PIN'));
    await tester.pumpAndSettle();

    // Dismiss PIN dialog without verifying -> balance remains intact
    await tester.tap(find.byKey(const Key('btn_close_pin_dialog')));
    await tester.pumpAndSettle();
    expect(find.text('Rp 12.450.000'), findsOneWidget);

    // Open again and test invalid then valid PIN
    await tester.tap(find.text('Tarik Saldo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konfirmasi & Masukkan PIN'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('VERIFIKASI'));
    await tester.pumpAndSettle();
    expect(find.text('PIN keamanan harus 6 digit angka'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '000000');
    await tester.tap(find.text('VERIFIKASI'));
    await tester.pumpAndSettle();
    expect(find.text('PIN keamanan salah (default: 123456)'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('VERIFIKASI'));
    await tester.pumpAndSettle();
    expect(find.text('Pengajuan Tarik Saldo Berhasil!'), findsOneWidget);

    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    expect(find.text('Rp 11.450.000'), findsOneWidget);
  });

  testWidgets('Finance AddBank requires Periksa check, respects Switch, and Settings opens dialog',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoFinanceScreen())));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    final saveBtn = find.text('Simpan Rekening');
    await tester.ensureVisible(saveBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();
    expect(find.text('Tekan Periksa untuk memverifikasi rekening terlebih dahulu'), findsOneWidget);

    final checkBtn = find.text('Periksa');
    await tester.ensureVisible(checkBtn);
    await tester.pumpAndSettle();
    await tester.tap(checkBtn);
    await tester.pumpAndSettle();
    expect(find.text('Nama Pemilik: MUHAMMAD TAUFIQ'), findsOneWidget);

    await tester.ensureVisible(saveBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();
    expect(find.text('Mandiri •••• 3741'), findsOneWidget);

    // Adding non-primary bank (Switch OFF) preserves active primary bank
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '9988776655');
    await tester.ensureVisible(find.text('Periksa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Periksa'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.ensureVisible(saveBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();
    expect(TokoState.activeBank.value, 'Mandiri •••• 3741');

    // Gear icon opens Finance settings dialog instead of duplicate bank sheet
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan Keuangan'), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
  });

  testWidgets('Menu validates empty input, supports Cemilan filter, and deletes item',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoMenuScreen())));
    expect(find.text('Semua (5)'), findsOneWidget);

    // Filter Cemilan exists and shows empty state initially
    final cemilanChip = find.text('Cemilan');
    await tester.ensureVisible(cemilanChip);
    await tester.pumpAndSettle();
    await tester.tap(cemilanChip);
    await tester.pumpAndSettle();
    expect(find.text('Menu tidak ditemukan'), findsOneWidget);

    final allChip = find.text('Semua (5)');
    await tester.ensureVisible(allChip);
    await tester.pumpAndSettle();
    await tester.tap(allChip);
    await tester.pumpAndSettle();

    // Validation on empty form
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    final submitBtn = find.text('Simpan Menu');
    await tester.ensureVisible(submitBtn);
    await tester.pumpAndSettle();
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();
    expect(find.text('Nama menu wajib diisi'), findsOneWidget);
    expect(find.text('Harga harus lebih dari Rp 0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    // Delete first menu item
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Semua (4)'), findsOneWidget);
  });

  testWidgets('Profile shows Warung Taufiq and syncs Buka/Tutup switch with TokoState',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoProfileScreen())));
    expect(find.text('Warung Taufiq'), findsOneWidget);
    expect(find.text('BUKA'), findsOneWidget);
    expect(find.text('Toko aktif menerima pesanan masuk'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(TokoState.isStoreOpen.value, isFalse);
    expect(find.text('TUTUP'), findsOneWidget);
    expect(find.text('Toko tutup sementara, pesanan dijeda'), findsOneWidget);
  });

  testWidgets('Finance filter chips toggle between Masuk and Keluar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoFinanceScreen())));
    expect(find.text('Tarik Saldo Berhasil'), findsOneWidget);
    expect(find.text('Pendapatan Hari Ini'), findsOneWidget);

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Tarik Saldo Berhasil'), findsOneWidget);
    expect(find.text('Pendapatan Hari Ini'), findsNothing);

    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Pendapatan Hari Ini'), findsOneWidget);
    expect(find.text('Tarik Saldo Berhasil'), findsNothing);

    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();
    expect(find.text('Tarik Saldo Berhasil'), findsOneWidget);
    expect(find.text('Pendapatan Hari Ini'), findsOneWidget);
  });

  testWidgets('Home notifications mark all read and reflect completed order revenue',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoHomeScreen())));
    expect(find.text('Rp 845.000'), findsOneWidget);
    expect(find.text('18 Pesanan'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // Mark all notifications as read
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_mark_all_read')));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Notifikasi'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('3'), findsNothing);

    // Complete non-COD order #FD-8821 (Rp 36.000) and verify sync across state and Home
    TokoState.completeOrder('#FD-8821');
    await tester.pumpAndSettle();
    expect(TokoState.balance.value, 12450000 + 36000);
    expect(TokoState.transactions.value.first['title'], 'Pendapatan Pesanan');
    expect(find.text('Rp 881.000'), findsOneWidget);
    expect(find.text('19 Pesanan'), findsOneWidget);
  });

  testWidgets('EditProfile and OperationalHours validate and persist changes',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoProfileScreen())));

    // Open Edit Profile via tile
    await tester.tap(find.text('Edit Profil Toko'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('input_edit_store_name')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('input_edit_store_name')), 'Dapur Nusantara');
    await tester.enterText(find.byKey(const Key('input_edit_owner_name')), 'Budi Santoso');
    await tester.tap(find.text('SIMPAN PERUBAHAN'));
    await tester.pumpAndSettle();

    expect(TokoState.storeName.value, 'Dapur Nusantara');
    expect(TokoState.ownerName.value, 'Budi Santoso');
    expect(find.text('Dapur Nusantara'), findsOneWidget);

    // Open Jam Operasional and test HH.MM validation
    final jamTile = find.text('Jam Operasional');
    await tester.ensureVisible(jamTile);
    await tester.pumpAndSettle();
    await tester.tap(jamTile);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('input_op_open')), '99:99');
    final saveHoursBtn = find.text('SIMPAN PERUBAHAN');
    await tester.ensureVisible(saveHoursBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveHoursBtn);
    await tester.pumpAndSettle();
    expect(TokoState.openHour.value, '08.00');

    // Open >= close (22.00 >= 21.00) must be rejected
    await tester.enterText(find.byKey(const Key('input_op_open')), '22.00');
    await tester.tap(saveHoursBtn);
    await tester.pumpAndSettle();
    expect(find.text('Jam tutup harus lebih besar dari jam buka'), findsOneWidget);
    expect(TokoState.openHour.value, '08.00');

    await tester.enterText(find.byKey(const Key('input_op_open')), '09.00');
    await tester.tap(saveHoursBtn);
    await tester.pumpAndSettle();
    expect(TokoState.openHour.value, '09.00');
  });

  testWidgets('Double-space storeName and customerName render without RangeError',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    TokoState.storeName.value = 'Warung  Baru';
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoHomeScreen())));
    expect(find.text('Warung  Baru'), findsOneWidget);
    expect(find.text('WB'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoProfileScreen())));
    expect(find.text('Warung  Baru'), findsOneWidget);

    final multiSpaceOrder = {
      'id': '#FD-9999',
      'tab': 'baru',
      'status': 'Perlu Diterima',
      'customerName': 'Budi   Santoso',
      'customerPhone': '081234567890',
      'customerDistance': '1.2 km',
      'deliveryAddress': 'Jl. Teuku Umar No. 10',
      'items': '1× Nasi Goreng',
      'itemDetails': [
        {
          'name': '1× Nasi Goreng',
          'price': 'Rp 25.000',
          'basePrice': 'Rp 25.000',
          'image': 'assets/images/food_nasgor.png',
        }
      ],
      'price': 'Rp 25.000',
      'total': 'Rp 25.000',
      'paymentMethod': 'RideOnPay',
      'orderTime': '12:00 WIB',
    };
    await tester.pumpWidget(MaterialApp(home: OrderDetailScreen(order: multiSpaceOrder)));
    expect(find.text('Budi   Santoso'), findsOneWidget);
    expect(find.text('BS'), findsOneWidget);
    expect(find.text('04:31'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('04:29'), findsOneWidget);
  });

  testWidgets('Missing or invalid local avatar path renders gracefully with AppImage',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    TokoState.ownerAvatar.value = '/non_existent_path/fake_avatar.png';
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoProfileScreen())));
    expect(find.text('Profil Toko'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(
      home: EditProfileScreen(initialAvatar: '/non_existent_path/fake_avatar.png'),
    ));
    expect(find.text('Ubah Profil'), findsOneWidget);
  });

  testWidgets('Home accept order assigns default courier info and marks notification read',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TokoHomeScreen())));
    expect(find.text('3'), findsOneWidget);

    final acceptBtn = find.text('Terima Pesanan');
    await tester.ensureVisible(acceptBtn);
    await tester.pumpAndSettle();
    await tester.tap(acceptBtn);
    await tester.pumpAndSettle();

    final accepted = TokoState.orders.value.firstWhere((o) => o['id'] == '#FD-8822');
    expect(accepted['tab'], 'diproses');
    expect(accepted['driverName'], isNotNull);
    expect(accepted['driverPlat'], isNotNull);
    expect(find.text('2'), findsOneWidget);
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
