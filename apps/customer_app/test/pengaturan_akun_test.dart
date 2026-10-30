import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rideon/features/pengaturan/presentation/pages/pengaturan_akun_screen.dart';
import 'package:rideon/features/auth/presentation/pages/forgot_password_screen.dart';

void main() {
  testWidgets('PengaturanAkunScreen renders all elements strictly matching Figma', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PengaturanAkunScreen(),
      ),
    );

    // Header & Profile Card
    expect(find.text('Pengaturan Akun'), findsOneWidget);
    expect(find.text('Peter'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('0812-3456-7890'), findsOneWidget);

    // Settings group
    expect(find.text('PENGATURAN AKUN'), findsOneWidget);
    expect(find.text('Ubah Profil'), findsOneWidget);
    expect(find.text('Ubah Tema'), findsOneWidget);
    expect(find.text('Nomor WhatsApp'), findsOneWidget);
    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Keamanan Akun'), findsOneWidget);
    expect(find.text('Lokasi Anda'), findsOneWidget);

    // Terms & Logout
    expect(find.text('Kebijakan Privasi & syarat'), findsOneWidget);
    expect(find.text('KELUAR AKUN'), findsOneWidget);
  });

  testWidgets('PengaturanAkunScreen opens Ubah Tema modal sheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PengaturanAkunScreen(),
      ),
    );

    await tester.tap(find.text('Ubah Tema'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Tema'), findsOneWidget);
    expect(find.text('Mode Terang'), findsOneWidget);
    expect(find.text('Mode Gelap'), findsOneWidget);
    expect(find.text('Ikuti Sistem'), findsOneWidget);
    expect(find.text('SELESAI'), findsOneWidget);

    // Select Mode Gelap and close
    await tester.tap(find.text('Mode Gelap'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SELESAI'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Tema'), findsNothing);
  });

  testWidgets('PengaturanAkunScreen opens Logout confirmation dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PengaturanAkunScreen(),
      ),
    );

    await tester.tap(find.text('KELUAR AKUN'));
    await tester.pumpAndSettle();

    expect(find.text('Keluar dari akun anda?'), findsOneWidget);
    expect(find.text('KELUAR'), findsOneWidget);
    expect(find.text('BATALKAN'), findsOneWidget);

    // Cancel dialog
    await tester.tap(find.text('BATALKAN'));
    await tester.pumpAndSettle();

    expect(find.text('Keluar dari akun anda?'), findsNothing);
  });

  testWidgets('PengaturanAkunScreen navigates to sub-screens', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PengaturanAkunScreen(),
      ),
    );

    // Test Ubah Profil navigation
    await tester.tap(find.text('Ubah Profil'));
    await tester.pumpAndSettle();
    expect(find.byType(UbahProfilScreen), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('SIMPAN PERUBAHAN'), findsOneWidget);

    // Go back
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(PengaturanAkunScreen), findsOneWidget);

    // Test Keamanan Akun navigation
    await tester.tap(find.text('Keamanan Akun'));
    await tester.pumpAndSettle();
    expect(find.byType(KeamananAkunScreen), findsOneWidget);
    expect(find.text('Kata Sandi Saat ini *'), findsOneWidget);
    expect(find.text('SIMPAN SANDI BARU'), findsOneWidget);

    // Go back
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(PengaturanAkunScreen), findsOneWidget);

    // Test Alamat Email navigation
    await tester.tap(find.text('Alamat Email'));
    await tester.pumpAndSettle();
    expect(find.byType(AlamatEmailScreen), findsOneWidget);
    expect(find.text('VERIFIKASI EMAIL'), findsOneWidget);

    // Go back
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(PengaturanAkunScreen), findsOneWidget);

    // Test Kebijakan Privasi navigation
    await tester.tap(find.text('Kebijakan Privasi & syarat'));
    await tester.pumpAndSettle();
    expect(find.byType(KebijakanPrivasiScreen), findsOneWidget);
    expect(find.text('Syarat & Ketentuan RideOn'), findsOneWidget);
  });

  testWidgets('NomorWaScreen renders 3 inputs and validates old phone match', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: NomorWaScreen(currentPhone: '+6285323441080'),
      ),
    );

    expect(find.text('Nomor WhatsApp'), findsOneWidget);
    expect(find.textContaining('+6285323441080'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi Akun'), findsOneWidget);
    expect(find.text('Nomor WhatsApp Lama'), findsOneWidget);
    expect(find.text('Nomor WhatsApp Baru'), findsOneWidget);
    expect(find.text('KIRIM KODE OTP WHATSAPP'), findsOneWidget);

    // 1. Tap send without filling fields -> Error kata sandi kosong
    await tester.tap(find.text('KIRIM KODE OTP WHATSAPP'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan kata sandi akun untuk konfirmasi keamanan.'), findsOneWidget);

    // 2. Isi kata sandi -> Error nomor lama kosong
    await tester.enterText(find.byType(TextField).at(0), 'password123');
    await tester.tap(find.text('KIRIM KODE OTP WHATSAPP'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan nomor WhatsApp lama akun Anda.'), findsOneWidget);

    // 3. Isi nomor lama yang salah -> Error nomor lama tidak cocok
    await tester.enterText(find.byType(TextField).at(1), '81234567890');
    await tester.enterText(find.byType(TextField).at(2), '85555555555');
    await tester.tap(find.text('KIRIM KODE OTP WHATSAPP'));
    await tester.pumpAndSettle();
    expect(find.text('Nomor WhatsApp lama yang Anda masukkan tidak sesuai dengan nomor terdaftar di akun.'), findsOneWidget);
  });

  testWidgets('AlamatEmailScreen adapts between 2-field (new) and 3-field (update) modes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Case 1: Belum ada email (2 Fields)
    await tester.pumpWidget(
      const MaterialApp(
        home: AlamatEmailScreen(currentEmail: ''),
      ),
    );

    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Hubungkan Email Anda'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi Akun'), findsOneWidget);
    expect(find.text('Alamat Email Aktif'), findsOneWidget);
    expect(find.text('Alamat Email Lama'), findsNothing);
    expect(find.text('VERIFIKASI EMAIL'), findsOneWidget);

    // Case 2: Sudah ada email (3 Fields)
    await tester.pumpWidget(
      const MaterialApp(
        home: AlamatEmailScreen(currentEmail: 'peter@gmail.com'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perbarui Alamat Email'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi Akun'), findsOneWidget);
    expect(find.text('Alamat Email Lama'), findsOneWidget);
    expect(find.text('Alamat Email Baru'), findsOneWidget);

    // Validasi submit kosong
    await tester.tap(find.text('VERIFIKASI EMAIL'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan kata sandi akun untuk konfirmasi keamanan.'), findsOneWidget);

    // Validasi email lama salah
    await tester.enterText(find.byType(TextField).at(0), 'password123');
    await tester.enterText(find.byType(TextField).at(1), 'wrong@gmail.com');
    await tester.enterText(find.byType(TextField).at(2), 'new@gmail.com');
    await tester.tap(find.text('VERIFIKASI EMAIL'));
    await tester.pumpAndSettle();
    expect(find.text('Alamat email lama yang Anda masukkan tidak sesuai dengan akun ini.'), findsOneWidget);
  });

  testWidgets('AlamatEmailScreen validates empty active email and invalid email format in 2-field mode', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: AlamatEmailScreen(currentEmail: ''),
      ),
    );

    // Enter password but leave active email empty
    await tester.enterText(find.byType(TextField).at(0), 'password123');
    await tester.tap(find.text('VERIFIKASI EMAIL'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan alamat email aktif Anda.'), findsOneWidget);

    // Enter invalid email format
    await tester.enterText(find.byType(TextField).at(1), 'invalid-email');
    await tester.tap(find.text('VERIFIKASI EMAIL'));
    await tester.pumpAndSettle();
    expect(find.text('Format alamat email tidak valid (contoh: user@gmail.com).'), findsOneWidget);
  });

  testWidgets('AlamatEmailScreen validates same new email as old email in 3-field mode', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: AlamatEmailScreen(currentEmail: 'peter@gmail.com'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'password123');
    await tester.enterText(find.byType(TextField).at(1), 'peter@gmail.com');
    await tester.enterText(find.byType(TextField).at(2), 'peter@gmail.com');
    await tester.tap(find.text('VERIFIKASI EMAIL'));
    await tester.pumpAndSettle();
    expect(find.text('Alamat email baru tidak boleh sama dengan email lama.'), findsOneWidget);
  });

  testWidgets('AlamatEmailScreen toggles password visibility eye icon', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: AlamatEmailScreen(currentEmail: ''),
      ),
    );

    // Initial password field is obscured
    final obscureFinder = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.obscureText == true,
    );
    expect(obscureFinder, findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    // Tap visibility icon to show password
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();

    final visibleFinder = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.obscureText == false,
    );
    expect(visibleFinder, findsWidgets);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('EmailVerificationDialog renders instructions, email, waiting indicator, and Batal button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmailVerificationDialog(
            newEmail: 'peter@gmail.com',
            pollInterval: Duration(hours: 1), // Prevent polling timer during layout test
          ),
        ),
      ),
    );

    expect(find.text('Tautan Verifikasi Terkirim!'), findsOneWidget);
    expect(find.textContaining('peter@gmail.com'), findsOneWidget);
    expect(find.textContaining('Silakan periksa Kotak Masuk (Inbox) atau folder Spam'), findsOneWidget);
    expect(find.text('Menunggu verifikasi dari Gmail...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
  });

  testWidgets('EmailVerificationDialog dismisses with false when Batal is pressed', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool? dialogResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                dialogResult = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => const EmailVerificationDialog(
                    newEmail: 'peter@gmail.com',
                    pollInterval: Duration(hours: 1),
                  ),
                );
              },
              child: const Text('OPEN DIALOG'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN DIALOG'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Tautan Verifikasi Terkirim!'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Tautan Verifikasi Terkirim!'), findsNothing);
    expect(dialogResult, isFalse);
  });

  testWidgets('EmailVerificationDialog polls and auto-dismisses with true when verified', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool? dialogResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                dialogResult = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => EmailVerificationDialog(
                    newEmail: 'peter@gmail.com',
                    pollInterval: const Duration(milliseconds: 50),
                    onCheckVerification: () async => true,
                  ),
                );
              },
              child: const Text('OPEN DIALOG'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN DIALOG'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('Tautan Verifikasi Terkirim!'), findsOneWidget);

    // Wait for the fast poll timer to trigger verification and pop dialog
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Tautan Verifikasi Terkirim!'), findsNothing);
    expect(dialogResult, isTrue);
  });

  testWidgets('PengaturanAkunScreen displays email section with initial Belum ditambahkan and +Tambahkan badge', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PengaturanAkunScreen(),
      ),
    );

    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('• Belum ditambahkan'), findsOneWidget);
    expect(find.text('+Tambahkan'), findsOneWidget);
  });

  testWidgets('KeamananAkunScreen renders all fields, hints, and Lupa kata sandi link', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: KeamananAkunScreen(),
      ),
    );

    expect(find.text('Keamanan Akun'), findsOneWidget);
    expect(find.text('Kata Sandi Saat ini *'), findsOneWidget);
    expect(find.text('Masukkan sandi saat ini'), findsOneWidget);
    expect(find.text('Lupa kata sandi?'), findsOneWidget);
    expect(find.text('Kata Sandi Baru *'), findsOneWidget);
    expect(find.text('Minimal 8 karakter'), findsOneWidget);
    expect(find.text('Konfirmasi Sandi Baru'), findsOneWidget);
    expect(find.text('Ketik ulang sandi baru'), findsOneWidget);
    expect(find.text('SIMPAN SANDI BARU'), findsOneWidget);
  });

  testWidgets('KeamananAkunScreen validates empty old password', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: KeamananAkunScreen(),
      ),
    );

    await tester.tap(find.text('SIMPAN SANDI BARU'));
    await tester.pumpAndSettle();

    expect(find.text('Masukkan kata sandi saat ini.'), findsOneWidget);
  });

  testWidgets('KeamananAkunScreen validates short new password (< 8 chars)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: KeamananAkunScreen(),
      ),
    );

    await tester.enterText(find.byKey(const Key('field_old_password')), 'oldpass123');
    await tester.enterText(find.byKey(const Key('field_new_password')), 'short');
    await tester.tap(find.text('SIMPAN SANDI BARU'));
    await tester.pumpAndSettle();

    expect(find.text('Kata sandi baru minimal 8 karakter.'), findsOneWidget);
  });

  testWidgets('KeamananAkunScreen validates new password same as old password', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: KeamananAkunScreen(),
      ),
    );

    await tester.enterText(find.byKey(const Key('field_old_password')), 'samepassword123');
    await tester.enterText(find.byKey(const Key('field_new_password')), 'samepassword123');
    await tester.tap(find.text('SIMPAN SANDI BARU'));
    await tester.pumpAndSettle();

    expect(find.text('Kata sandi baru tidak boleh sama dengan kata sandi saat ini.'), findsOneWidget);
  });

  testWidgets('KeamananAkunScreen validates password mismatch between new password and confirmation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: KeamananAkunScreen(),
      ),
    );

    await tester.enterText(find.byKey(const Key('field_old_password')), 'oldpassword123');
    await tester.enterText(find.byKey(const Key('field_new_password')), 'newpassword123');
    await tester.enterText(find.byKey(const Key('field_confirm_password')), 'different123');
    await tester.tap(find.text('SIMPAN SANDI BARU'));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi kata sandi baru tidak cocok.'), findsOneWidget);
  });

  testWidgets('KeamananAkunScreen toggles password visibility for all 3 fields', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: KeamananAkunScreen(),
      ),
    );

    // Initial state: all 3 textfields are obscured
    final obscureFinder = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.obscureText == true,
    );
    expect(obscureFinder, findsNWidgets(3));
    expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(3));
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);

    // Toggle field 1
    await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));

    // Toggle field 2
    await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    // Toggle field 3
    await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(3));
    expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
  });

  testWidgets('KeamananAkunScreen navigates to ForgotPasswordScreen when clicking Lupa kata sandi?', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: KeamananAkunScreen(),
      ),
    );

    await tester.tap(find.text('Lupa kata sandi?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
  });

  testWidgets('KeamananAkunScreen updates password successfully, shows success dialog modal, and pops', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool passwordUpdated = false;
    bool? popResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              popResult = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (ctx) => KeamananAkunScreen(
                    onUpdatePassword: (oldP, newP) async {
                      passwordUpdated = true;
                    },
                  ),
                ),
              );
            },
            child: const Text('OPEN KEAMANAN AKUN'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN KEAMANAN AKUN'));
    await tester.pumpAndSettle();

    expect(find.byType(KeamananAkunScreen), findsOneWidget);

    await tester.enterText(find.byKey(const Key('field_old_password')), 'oldpassword123');
    await tester.enterText(find.byKey(const Key('field_new_password')), 'newpassword123');
    await tester.enterText(find.byKey(const Key('field_confirm_password')), 'newpassword123');

    await tester.tap(find.text('SIMPAN SANDI BARU'));
    await tester.pumpAndSettle();

    expect(passwordUpdated, isTrue);

    // Verify dialog modal appeared
    expect(find.text('Kata Sandi Berhasil Diperbarui!'), findsOneWidget);
    expect(
      find.text('Kata sandi akun Anda telah berhasil diperbarui. Gunakan kata sandi baru ini untuk masuk ke akun RideOn berikutnya.'),
      findsOneWidget,
    );
    expect(find.text('SELESAI'), findsOneWidget);

    // Tap SELESAI
    await tester.tap(find.text('SELESAI'));
    await tester.pumpAndSettle();

    // Dialog and KeamananAkunScreen should both be popped
    expect(find.byType(KeamananAkunScreen), findsNothing);
    expect(popResult, isTrue);
  });

  testWidgets('KeamananAkunScreen displays error message banner when password update fails', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: KeamananAkunScreen(
          onUpdatePassword: (oldP, newP) async {
            throw 'Kata sandi saat ini yang Anda masukkan salah.';
          },
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('field_old_password')), 'wrongpassword');
    await tester.enterText(find.byKey(const Key('field_new_password')), 'newpassword123');
    await tester.enterText(find.byKey(const Key('field_confirm_password')), 'newpassword123');

    await tester.tap(find.text('SIMPAN SANDI BARU'));
    await tester.pumpAndSettle();

    expect(find.text('Kata sandi saat ini yang Anda masukkan salah.'), findsOneWidget);
  });

  testWidgets('KeamananAkunScreen maps FirebaseAuthException error codes correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String errorCodeToThrow = 'wrong-password';

    await tester.pumpWidget(
      MaterialApp(
        home: KeamananAkunScreen(
          onUpdatePassword: (oldP, newP) async {
            throw FirebaseAuthException(code: errorCodeToThrow);
          },
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('field_old_password')), 'wrongpassword');
    await tester.enterText(find.byKey(const Key('field_new_password')), 'newpassword123');
    await tester.enterText(find.byKey(const Key('field_confirm_password')), 'newpassword123');

    // Test wrong-password
    await tester.tap(find.text('SIMPAN SANDI BARU'));
    await tester.pumpAndSettle();
    expect(find.text('Kata sandi saat ini yang Anda masukkan salah.'), findsOneWidget);

    // Test weak-password
    errorCodeToThrow = 'weak-password';
    await tester.tap(find.text('SIMPAN SANDI BARU'));
    await tester.pumpAndSettle();
    expect(find.text('Kata sandi baru terlalu lemah.'), findsOneWidget);

    // Test too-many-requests
    errorCodeToThrow = 'too-many-requests';
    await tester.tap(find.text('SIMPAN SANDI BARU'));
    await tester.pumpAndSettle();
    expect(find.text('Terlalu banyak percobaan. Silakan coba lagi beberapa saat.'), findsOneWidget);
  });

  testWidgets('KeamananAkunScreen clears error banner when typing in fields', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: KeamananAkunScreen(),
      ),
    );

    // Trigger validation error
    await tester.tap(find.text('SIMPAN SANDI BARU'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan kata sandi saat ini.'), findsOneWidget);

    // Enter text to clear error
    await tester.enterText(find.byKey(const Key('field_old_password')), 'a');
    await tester.pumpAndSettle();
    expect(find.text('Masukkan kata sandi saat ini.'), findsNothing);
  });

  testWidgets('KeamananAkunScreen handles system pop on success dialog and pops screen with true', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool? popResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              popResult = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (ctx) => KeamananAkunScreen(
                    onUpdatePassword: (oldP, newP) async {},
                  ),
                ),
              );
            },
            child: const Text('OPEN'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('field_old_password')), 'oldpassword123');
    await tester.enterText(find.byKey(const Key('field_new_password')), 'newpassword123');
    await tester.enterText(find.byKey(const Key('field_confirm_password')), 'newpassword123');

    await tester.tap(find.text('SIMPAN SANDI BARU'));
    await tester.pumpAndSettle();

    expect(find.text('Kata Sandi Berhasil Diperbarui!'), findsOneWidget);

    // Simulate system back gesture
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(KeamananAkunScreen), findsNothing);
    expect(popResult, isTrue);
  });

  testWidgets('PengaturanAkunScreen shows SnackBar when KeamananAkunScreen returns true', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PengaturanAkunScreen(),
      ),
    );

    await tester.tap(find.text('Keamanan Akun'));
    await tester.pumpAndSettle();
    expect(find.byType(KeamananAkunScreen), findsOneWidget);

    // Simulate pop with true from KeamananAkunScreen
    Navigator.of(tester.element(find.byType(KeamananAkunScreen))).pop(true);
    await tester.pumpAndSettle();

    expect(find.byType(PengaturanAkunScreen), findsOneWidget);
    expect(find.text('Kata sandi berhasil diperbarui!'), findsOneWidget);
  });
}
