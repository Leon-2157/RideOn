import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideon/features/pengaturan/presentation/pages/pengaturan_akun_screen.dart';

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

    // Test Kebijakan Privasi navigation
    await tester.tap(find.text('Kebijakan Privasi & syarat'));
    await tester.pumpAndSettle();
    expect(find.byType(KebijakanPrivasiScreen), findsOneWidget);
    expect(find.text('Syarat & Ketentuan RideOn'), findsOneWidget);
  });
}
