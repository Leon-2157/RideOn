import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rideon/features/pengaturan/presentation/pages/lokasi_anda_screen.dart';

void main() {
  testWidgets('LokasiAndaScreen renders map, center pin, GPS button, labels, and save button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: LokasiAndaScreen(
          initialCenter: LatLng(5.2472, 97.0261),
        ),
      ),
    );

    await tester.pump();

    // Verify Header
    expect(find.text('Lokasi Anda'), findsOneWidget);

    // Verify Map Overlay Text & Center Pin Instruction
    expect(find.text('Geser peta untuk atur titik'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_rounded), findsWidgets);

    // Verify Control Card
    expect(find.text('Atur Lokasi Anda'), findsOneWidget);
    expect(find.text('Gunakan Titik GPS Saat Ini'), findsOneWidget);
    expect(find.byKey(const Key('btn_gunakan_titik_gps')), findsOneWidget);

    // Verify Multi-Label Options
    expect(find.text('Simpan Sebagai'), findsOneWidget);
    expect(find.text('Rumah'), findsOneWidget);
    expect(find.text('Kantor'), findsOneWidget);
    expect(find.text('Kost'), findsOneWidget);
    expect(find.text('Lainnya'), findsOneWidget);

    // Verify Detail Alamat Section
    expect(find.text('Detail Alamat Lengkap'), findsOneWidget);

    // Verify Note Field Hint
    expect(find.text('Catatan patokan (contoh: Pagar hitam No. 12)'), findsOneWidget);

    // Verify Save Button
    expect(find.text('SIMPAN TITIK LOKASI'), findsOneWidget);
    expect(find.byKey(const Key('btn_simpan_titik_lokasi')), findsOneWidget);

    // Test Selecting a different label (e.g., 'Kantor')
    await tester.tap(find.text('Kantor'));
    await tester.pump();

    // Enter Note
    await tester.enterText(
      find.byType(TextField),
      'Pagar warna hitam nomor 45 samping musholla',
    );
    await tester.pump();
    expect(find.text('Pagar warna hitam nomor 45 samping musholla'), findsOneWidget);
  });
}

