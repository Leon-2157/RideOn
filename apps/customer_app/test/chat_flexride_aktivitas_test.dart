import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideon/features/aktivitas/presentation/pages/aktivitas_screen.dart';
import 'package:rideon/features/chat/presentation/pages/chat_screen.dart';
import 'package:rideon/features/flexride/presentation/pages/flexride_screen.dart';
import 'package:rideon/features/main/presentation/pages/main_screen.dart';

void main() {
  testWidgets('AktivitasScreen renders transaction list and receipt modal', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AktivitasScreen(),
      ),
    );

    expect(find.text('Riwayat Aktivitas'), findsOneWidget);
    expect(find.text('Nasi Goreng Mas Fuad'), findsOneWidget);
    expect(find.text('Perjalanan Ojek Motor'), findsOneWidget);

    // Tap on first transaction to show receipt
    await tester.tap(find.text('Nasi Goreng Mas Fuad'));
    await tester.pumpAndSettle();

    expect(find.text('Rangkuman Aktivitas'), findsOneWidget);
  });

  testWidgets('ChatScreen renders driver info and sends message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChatScreen(),
      ),
    );

    expect(find.text('Pikri Haykal'), findsOneWidget);
    expect(find.text('Honda Vario 160 Hitam • BG 4563 R'), findsOneWidget);
    expect(find.text('Ketik pesan untuk driver...'), findsOneWidget);

    // Tap quick reply
    await tester.tap(find.text('Boleh mas, sekalian aja').first);
    await tester.pump();
  });

  testWidgets('FlexRideScreen performs location input and vehicle selection', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FlexRideScreen(),
      ),
    );

    expect(find.text('Pesan FlexRide'), findsOneWidget);
    expect(find.text('Alamat Favorit & Riwayat Cepat'), findsOneWidget);

    // Tap proceed to vehicles
    await tester.tap(find.text('Lanjut Pilih Kendaraan'));
    await tester.pumpAndSettle();

    expect(find.text('Flex Motor'), findsOneWidget);
    expect(find.text('Flex Mobil'), findsOneWidget);
  });

  testWidgets('MainScreen switches to Aktivitas and Chat tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainScreen(),
      ),
    );

    // Tap on Aktivitas tab
    await tester.tap(find.text('Aktivitas'));
    await tester.pumpAndSettle();
    expect(find.byType(AktivitasScreen), findsOneWidget);

    // Tap on chat tab
    await tester.tap(find.text('chat'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
  });
}
