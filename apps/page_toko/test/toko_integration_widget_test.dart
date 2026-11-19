import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_toko/data/toko_state.dart';
import 'package:page_toko/screens/finance/toko_finance_screen.dart';
import 'package:page_toko/screens/home/toko_home_screen.dart';
import 'package:page_toko/screens/menu/toko_menu_screen.dart';
import 'package:page_toko/services/toko_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TokoApiService.enableLocalFallback = false;
    await TokoApiService().logout();
    TokoState.resetForTest();
  });

  tearDown(() {
    TokoApiService().clientOverride = null;
  });

  testWidgets('PENDING_APPROVAL store shows verification banner and locks open switch',
      (WidgetTester tester) async {
    TokoState.userStatus.value = 'PENDING_APPROVAL';
    TokoState.isStoreOpen.value = false;

    await tester.pumpWidget(const MaterialApp(home: TokoHomeScreen()));
    await tester.pump();

    expect(find.byKey(const Key('banner_toko_pending_verification')), findsOneWidget);
    expect(find.text('Menunggu Verifikasi Admin'), findsOneWidget);

    final sw = tester.widget<Switch>(find.byKey(const Key('switch_toko_open_status')));
    expect(sw.onChanged, isNull);
    expect(sw.value, isFalse);
  });

  testWidgets('TokoFinanceScreen shows AI Sales Insight & opens CS AI Mitra Toko sheet',
      (WidgetTester tester) async {
    TokoApiService().clientOverride = MockClient((req) async {
      if (req.url.path == '/ai/chat') {
        return http.Response(
          jsonEncode({'reply': 'Penjualan Mie Aceh naik 15% hari ini.'}),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(const MaterialApp(home: TokoFinanceScreen()));
    await tester.pump();

    expect(find.text('AI Sales Insight'), findsOneWidget);
    await tester.tap(find.byKey(const Key('btn_toko_ai_insight')));
    await tester.pumpAndSettle();
    expect(find.text('Penjualan Mie Aceh naik 15% hari ini.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_toko_cs_ai')));
    await tester.pumpAndSettle();
    expect(find.text('CS AI Mitra Toko'), findsOneWidget);
    expect(find.byKey(const Key('btn_toko_create_ticket')), findsOneWidget);
  });

  testWidgets('TokoMenuScreen AI Copywriter populates menu description',
      (WidgetTester tester) async {
    TokoApiService().clientOverride = MockClient((req) async {
      if (req.url.path == '/ai/chat') {
        return http.Response(
          jsonEncode({'reply': 'Mie Aceh goreng pedas gurih dengan taburan bawang goreng renyah.'}),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(const MaterialApp(home: TokoMenuScreen()));
    await tester.pump();

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Masukkan nama menu'), 'Mie Aceh');
    final aiBtn = find.byKey(const Key('btn_ai_menu_description'));
    await tester.ensureVisible(aiBtn);
    await tester.pumpAndSettle();
    await tester.tap(aiBtn);
    await tester.pumpAndSettle();

    expect(
      find.text('Mie Aceh goreng pedas gurih dengan taburan bawang goreng renyah.'),
      findsOneWidget,
    );
  });
}
