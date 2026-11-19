import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/screens/radar/radar_screen.dart';
import 'package:driver_app/screens/wallet/wallet_screen.dart';
import 'package:driver_app/services/driver_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DriverApiService().resetForTest();
  });

  testWidgets(
      'RadarScreen with PENDING_APPROVAL displays banner and disables Go Online switch',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RadarScreen(
          driverName: 'Calon Driver',
          userStatus: 'PENDING_APPROVAL',
          initialIsOnline: false,
          initialOrderState: RadarOrderState.dashboard,
          enableRadarAnimation: false,
          enableGpsTracking: false,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('banner_pending_approval')), findsOneWidget);
    expect(find.textContaining('diverifikasi Admin'), findsOneWidget);

    final sw = tester.widget<Switch>(
      find.byKey(const Key('switch_driver_online')),
    );
    expect(sw.value, isFalse);
    expect(sw.onChanged, isNull);
  });

  testWidgets('WalletScreen displays negative balance banner when balance < 0',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WalletScreen(
          initialBalance: -15000,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('banner_negative_balance')), findsOneWidget);
    expect(find.textContaining('Saldo Minus'), findsOneWidget);
  });
}

