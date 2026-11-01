import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/screens/account_settings/account_settings_screen.dart';
import 'package:driver_app/screens/account_settings/edit_profile_screen.dart';
import 'package:driver_app/screens/account_settings/driver_verification_screen.dart';
import 'package:driver_app/screens/account_settings/vehicle_info_screen.dart';
import 'package:driver_app/screens/account_settings/security_screen.dart';
import 'package:driver_app/screens/account_settings/privacy_policy_screen.dart';
import 'package:driver_app/screens/account_settings/theme_selection_sheet.dart';
import 'package:driver_app/screens/account_settings/logout_dialog.dart';
import 'package:driver_app/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pengaturan Akun Screen & Sub-screens Tests', () {
    testWidgets('AccountSettingsScreen renders profile card and all menu items',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AccountSettingsScreen(
            initialDriverName: 'Joni Utama',
            initialPlateNumber: 'BK 4892 ABC',
          ),
        ),
      );

      // Verifikasi Header
      expect(find.text('Pengaturan Akun'), findsOneWidget);

      // Verifikasi Profil Driver
      expect(find.text('Joni Utama'), findsOneWidget);
      expect(find.textContaining('BK 4892 ABC', findRichText: true), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);

      // Verifikasi Menu Utama
      expect(find.text('PENGATURAN AKUN'), findsOneWidget);
      expect(find.text('Ubah Profil'), findsOneWidget);
      expect(find.text('Nama dan foto akun'), findsOneWidget);
      expect(find.text('Ubah Tema'), findsOneWidget);
      expect(find.text('Status Verifikasi'), findsOneWidget);
      expect(find.text('Informasi Kendaraan'), findsOneWidget);
      expect(find.text('Keamanan Akun'), findsOneWidget);

      // Verifikasi Kebijakan Privasi
      expect(find.text('Kebijakan Privasi & syarat'), findsOneWidget);
      expect(find.text('Ketentuan Penggunaan Platfrom'), findsOneWidget);

      // Verifikasi Tombol Keluar
      expect(find.text('KELUAR AKUN'), findsOneWidget);
    });

    testWidgets('Tapping KELUAR AKUN shows LogoutDialog with confirm and cancel buttons',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool logoutCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AccountSettingsScreen(
            onLogout: () {
              logoutCalled = true;
            },
          ),
        ),
      );

      final keluarBtn = find.text('KELUAR AKUN');
      await tester.ensureVisible(keluarBtn);
      await tester.tap(keluarBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LogoutDialog), findsOneWidget);
      expect(find.text('Keluar dari akun anda?'), findsOneWidget);
      expect(find.text('KELUAR'), findsOneWidget);
      expect(find.text('BATALKAN'), findsOneWidget);

      // Klik KELUAR
      await tester.tap(find.text('KELUAR'));
      await tester.pumpAndSettle();

      expect(logoutCalled, isTrue);
    });

    testWidgets('Tapping Ubah Tema opens ThemeSelectionSheet with options',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AccountSettingsScreen(),
        ),
      );

      await tester.tap(find.text('Ubah Tema'));
      await tester.pumpAndSettle();

      expect(find.byType(ThemeSelectionSheet), findsOneWidget);
      expect(find.text('Pilih Tema'), findsOneWidget);
      expect(find.text('Mode Terang'), findsOneWidget);
      expect(find.text('Mode Gelap'), findsOneWidget);
      expect(find.text('Ikuti Sistem'), findsOneWidget);
      expect(find.text('SELESAI'), findsOneWidget);

      // Tap Selesai
      await tester.tap(find.text('SELESAI'));
      await tester.pumpAndSettle();
      expect(find.byType(ThemeSelectionSheet), findsNothing);
    });

    testWidgets('Tapping Mode Gelap in ThemeSelectionSheet activates dark theme',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        ThemeService().reset();
      });

      ThemeService().reset();

      await tester.pumpWidget(
        const MaterialApp(
          home: AccountSettingsScreen(),
        ),
      );

      await tester.tap(find.text('Ubah Tema'));
      await tester.pumpAndSettle();

      // Tap Mode Gelap
      await tester.tap(find.text('Mode Gelap'));
      await tester.pumpAndSettle();

      // ThemeService immediately sets dark theme
      expect(ThemeService().currentTheme, AppThemeMode.dark);

      // Tap Selesai
      await tester.tap(find.text('SELESAI'));
      await tester.pumpAndSettle();

      expect(ThemeService().currentTheme, AppThemeMode.dark);
      expect(ThemeService().themeMode, ThemeMode.dark);
    });

    testWidgets('Tapping Mode Terang in ThemeSelectionSheet activates light theme',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        ThemeService().reset();
      });

      ThemeService().setTheme(AppThemeMode.dark);

      await tester.pumpWidget(
        const MaterialApp(
          home: AccountSettingsScreen(),
        ),
      );

      await tester.tap(find.text('Ubah Tema'));
      await tester.pumpAndSettle();

      // Tap Mode Terang
      await tester.tap(find.text('Mode Terang'));
      await tester.pumpAndSettle();

      expect(ThemeService().currentTheme, AppThemeMode.light);

      // Tap Selesai
      await tester.tap(find.text('SELESAI'));
      await tester.pumpAndSettle();

      expect(ThemeService().currentTheme, AppThemeMode.light);
      expect(ThemeService().themeMode, ThemeMode.light);
    });

    testWidgets('EditProfileScreen renders avatar, text field and saves name',
        (WidgetTester tester) async {
      String? savedName;

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileScreen(
            initialName: 'Joni Utama',
            onNameSaved: (name) {
              savedName = name;
            },
          ),
        ),
      );

      expect(find.text('Ubah Profil'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Joni Utama'), findsOneWidget);
      expect(find.text('SIMPAN PERUBAHAN'), findsOneWidget);

      // Edit nama
      await tester.enterText(find.byType(TextField), 'Peter Parker');
      await tester.tap(find.text('SIMPAN PERUBAHAN'));
      await tester.pumpAndSettle();

      expect(savedName, equals('Peter Parker'));
    });

    testWidgets('DriverVerificationScreen renders verification status and documents',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DriverVerificationScreen(
            status: 'Terverifikasi',
            verificationDate: '15 Oktober 2026',
          ),
        ),
      );

      expect(find.text('Verifikasi Driver'), findsWidgets);
      expect(find.text('Pastikan data dan dokumen kamu sudah lengkap.'), findsOneWidget);
      expect(find.text('Status Akun'), findsOneWidget);
      expect(find.text('Terverifikasi'), findsOneWidget);
      expect(find.text('Dokumen Pengemudi'), findsOneWidget);
      expect(find.text('KTP'), findsOneWidget);
      expect(find.text('SIM C'), findsOneWidget);
      expect(find.text('STNK'), findsOneWidget);
      expect(find.text('15 Oktober 2026'), findsOneWidget);
    });

    testWidgets('VehicleInfoScreen renders motorcycle specs and triggers edit mode',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: VehicleInfoScreen(
            brand: 'Honda',
            model: 'Vario 160',
            plateNumber: 'BL 1234 XX',
            color: 'Merah',
            year: '2024',
          ),
        ),
      );

      expect(find.text('Honda Vario 160'), findsOneWidget);
      expect(find.text('Sepeda Motor'), findsOneWidget);
      expect(find.text('Detail Kendaraan'), findsOneWidget);
      expect(find.text('Merek Kendaraan'), findsOneWidget);
      expect(find.text('Honda'), findsOneWidget);
      expect(find.text('BL 1234 XX'), findsOneWidget);
      expect(find.text('Ubah Informasi Kendaraan'), findsOneWidget);

      // Masuk ke mode edit
      final ubahBtn = find.text('Ubah Informasi Kendaraan');
      await tester.ensureVisible(ubahBtn);
      await tester.tap(ubahBtn);
      await tester.pumpAndSettle();

      expect(find.text('Perbarui'), findsOneWidget);
    });

    testWidgets('SecurityScreen validates password input and displays error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecurityScreen(),
        ),
      );

      expect(find.text('Keamanan Akun'), findsOneWidget);
      expect(find.text('Kata Sandi Saat ini *'), findsOneWidget);
      expect(find.text('Kata Sandi Baru *'), findsOneWidget);
      expect(find.text('Konfirmasi Sandi Baru'), findsOneWidget);
      expect(find.text('SIMPAN SANDI BARU'), findsOneWidget);

      // Klik simpan tanpa input kata sandi
      await tester.tap(find.text('SIMPAN SANDI BARU'));
      await tester.pumpAndSettle();

      expect(find.text('Kata sandi saat ini tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('PrivacyPolicyScreen renders full terms and conditions content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacyPolicyScreen(),
        ),
      );

      expect(find.text('Kebijakan Privasi & syarat'), findsOneWidget);
      expect(find.text('Syarat & Ketentuan RideOn'), findsOneWidget);
      expect(find.text('Ketentuan umum penggunaan layanan transportas'), findsOneWidget);
      expect(find.text('1. Ketentuan Umum & Definisi'), findsOneWidget);
      expect(find.text('2. Tanggung Jawab & Kewajiban Customer'), findsOneWidget);
    });
  });
}
