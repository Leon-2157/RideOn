import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/screens/login_screen.dart';
import 'package:driver_app/screens/register/register_screen.dart';
import 'package:driver_app/screens/register/register_upload_docs_screen.dart';
import 'package:driver_app/screens/register/photo_picker_sheet.dart';
import 'package:driver_app/screens/register/terms_and_conditions_sheet.dart';
import 'package:driver_app/screens/register/register_success_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pendaftaran Mitra Driver (Daftar Sekarang) Tests', () {
    testWidgets('LoginScreen tapping Daftar Sekarang navigates to RegisterScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Cari dan tekan link "Daftar Sekarang"
      final linkDaftar = find.byKey(const Key('link_daftar_sekarang'));
      expect(linkDaftar, findsOneWidget);

      await tester.tap(linkDaftar);
      await tester.pumpAndSettle();

      // Memastikan navigasi ke RegisterScreen
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('Daftar Akun Driver'), findsOneWidget);
    });

    testWidgets(
        'RegisterScreen renders form fields and validates inputs matching Figma',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      // Verifikasi komponen sesuai Figma Daftar akun_step 1.png
      expect(find.text('Daftar Akun Driver'), findsOneWidget);
      expect(find.text('Lengkapi data diri Anda untuk memulai'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('No. WhatsApp Aktif'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Kata sandi (Min. 8 karakter)'), findsOneWidget);
      expect(find.text('Ulangi Kata Sandi'), findsOneWidget);
      expect(find.text('LANJUTKAN'), findsOneWidget);
      expect(find.textContaining('Masuk di sini', findRichText: true), findsOneWidget);

      // 1. Submit kosong -> validasi gagal
      await tester.tap(find.byKey(const Key('btn_lanjutkan_register')));
      await tester.pumpAndSettle();
      expect(find.text('Harap lengkapi seluruh kolom formulir.'), findsOneWidget);

      // 2. Isi Nama & Phone & Email tidak valid
      await tester.enterText(
          find.byKey(const Key('input_register_name')), 'Joni Utama');
      await tester.enterText(
          find.byKey(const Key('input_register_phone')), '08123456789');
      await tester.enterText(
          find.byKey(const Key('input_register_email')), 'invalid-email');
      await tester.enterText(
          find.byKey(const Key('input_register_password')), 'Password123');
      await tester.enterText(
          find.byKey(const Key('input_register_confirm_password')), 'Password123');
      await tester.tap(find.byKey(const Key('btn_lanjutkan_register')));
      await tester.pumpAndSettle();
      expect(find.text('Format email tidak valid.'), findsOneWidget);

      // 3. Sandi kurang dari 8 karakter
      await tester.enterText(
          find.byKey(const Key('input_register_email')), 'joni@example.com');
      await tester.enterText(
          find.byKey(const Key('input_register_password')), '12345');
      await tester.enterText(
          find.byKey(const Key('input_register_confirm_password')), '12345');
      await tester.tap(find.byKey(const Key('btn_lanjutkan_register')));
      await tester.pumpAndSettle();
      expect(find.text('Kata sandi minimal harus 8 karakter.'), findsOneWidget);

      // 4. Konfirmasi kata sandi tidak cocok
      await tester.enterText(
          find.byKey(const Key('input_register_password')), 'Driver210526');
      await tester.enterText(
          find.byKey(const Key('input_register_confirm_password')), 'Driver210599');
      await tester.tap(find.byKey(const Key('btn_lanjutkan_register')));
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi kata sandi tidak cocok.'), findsOneWidget);

      // 5. Toggle password visibility
      final passField = tester.widget<TextField>(
          find.byKey(const Key('input_register_password')));
      expect(passField.obscureText, isTrue);

      await tester.tap(find.byKey(const Key('toggle_register_password')));
      await tester.pumpAndSettle();
      final passFieldVisible = tester.widget<TextField>(
          find.byKey(const Key('input_register_password')));
      expect(passFieldVisible.obscureText, isFalse);

      // 6. Data valid -> Navigasi ke RegisterUploadDocsScreen
      await tester.enterText(
          find.byKey(const Key('input_register_confirm_password')), 'Driver210526');
      await tester.tap(find.byKey(const Key('btn_lanjutkan_register')));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterUploadDocsScreen), findsOneWidget);
      expect(find.text('Lengkapi Berkas'), findsOneWidget);
    });

    testWidgets(
        'RegisterUploadDocsScreen handles document upload, terms sheet, and submission',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterUploadDocsScreen(
            fullName: 'Joni Utama',
            phone: '08123456789',
            email: 'joni@example.com',
            password: 'Password123',
          ),
        ),
      );

      // Verifikasi 5 dokumen sesuai Figma Daftar akun_step 2.png
      expect(find.text('Identitas Pribadi (KTP)'), findsOneWidget);
      expect(find.text('Surat Izin Mengemudi (SIM)'), findsOneWidget);
      expect(find.text('Surat Tanda Nomor Kendaraan (STNK)'), findsOneWidget);
      expect(find.text('Informasi Rekening Bank'), findsOneWidget);
      expect(find.text('Surat Keterangan Catatan Kepolisian (SKCK)'), findsOneWidget);
      expect(find.text('UPLOAD'), findsOneWidget);

      // Submit sebelum upload -> error
      await tester.tap(find.byKey(const Key('btn_upload_berkas')));
      await tester.pumpAndSettle();
      expect(
        find.text('Harap lengkapi semua dokumen yang diperlukan.'),
        findsOneWidget,
      );

      // Upload KTP via modal PhotoPickerSheet
      await tester.tap(find.byKey(const Key('tile_doc_ktp')));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoPickerSheet), findsOneWidget);
      expect(find.text('Pilih Foto'), findsOneWidget);
      expect(find.text('Ambil Foto'), findsOneWidget);
      expect(find.text('Pilih Dari Galeri'), findsOneWidget);

      // Pilih Galeri
      await tester.tap(find.byKey(const Key('opt_pilih_galeri')));
      await tester.pumpAndSettle();

      // Badge "Terupload" muncul pada KTP (Figma Daftar akun_step 4.png)
      expect(find.text('Terupload'), findsOneWidget);

      // Upload sisa 4 dokumen
      for (final docId in ['sim', 'stnk', 'bank', 'skck']) {
        await tester.tap(find.byKey(Key('tile_doc_$docId')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('opt_ambil_foto')));
        await tester.pumpAndSettle();
      }

      // Seluruh 5 dokumen berstatus "Terupload" (Figma Daftar akun_step 5.png)
      expect(find.text('Terupload'), findsNWidgets(5));

      // Buka dan setujui Syarat & Ketentuan dari modal bottom sheet
      await tester.tap(find.byKey(const Key('link_terms_bottomsheet')));
      await tester.pumpAndSettle();

      expect(find.byType(TermsAndConditionsSheet), findsOneWidget);
      expect(find.text('Syarat & Ketentuan RideOn'), findsOneWidget);
      expect(find.text('1. Ketentuan Umum & Definisi'), findsOneWidget);
      expect(find.text('4. Batasan Tanggung Jawab'), findsOneWidget);

      // Tekan "SAYA MENGERTI & SETUJU"
      await tester.tap(find.byKey(const Key('btn_setuju_syarat_ketentuan')));
      await tester.pumpAndSettle();

      // Checkbox otomatis tercentang
      final checkbox = tester.widget<Checkbox>(find.byKey(const Key('checkbox_terms')));
      expect(checkbox.value, isTrue);

      // Tekan tombol UPLOAD -> Navigasi ke RegisterSuccessScreen
      await tester.tap(find.byKey(const Key('btn_upload_berkas')));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterSuccessScreen), findsOneWidget);
      expect(find.text('BERKAS BERHASIL DI UPLOAD'), findsOneWidget);
      expect(find.text('CEK EMAIL SEKARANG'), findsOneWidget);
      expect(find.text('Bantuan Pendaftaran Mitra (CS WhatsApp)'), findsOneWidget);
    });

    testWidgets('RegisterSuccessScreen actions trigger callbacks',
        (WidgetTester tester) async {
      bool emailChecked = false;
      bool helpClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: RegisterSuccessScreen(
            onCheckEmail: () => emailChecked = true,
            onHelpWhatsApp: () => helpClicked = true,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('btn_cek_email')));
      expect(emailChecked, isTrue);

      await tester.tap(find.byKey(const Key('link_bantuan_cs_wa')));
      expect(helpClicked, isTrue);
    });
  });
}
