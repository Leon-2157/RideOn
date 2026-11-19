import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rideon/core/models/customer_models.dart';
import 'package:rideon/core/services/customer_api_service.dart';
import 'package:rideon/features/chat/presentation/modules/inbox/inbox_view.dart';
import 'package:rideon/features/flexfood/presentation/modules/checkout/checkout_view.dart';
import 'package:rideon/features/flexride/presentation/pages/flexride_screen.dart';
import 'package:rideon/features/home/presentation/pages/beranda_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CustomerApiService.enableLocalFallback = false;
    CustomerApiService().resetForTest();
  });

  tearDown(() {
    CustomerApiService.enableLocalFallback = false;
    CustomerApiService().resetForTest();
  });

  group('CustomerModels JSON serialization', () {
    test('deserializes and serializes CustomerModels accurately', () {
      final user = CustomerUser.fromJson({
        'id': 'u-1',
        'name': 'Cut Meutia',
        'email': 'cut.meutia@mhs.unimal.ac.id',
        'phone': '6285260000401',
        'role': 'CUSTOMER',
        'status': 'ACTIVE',
        'avatar_url': '/uploads/avatar.png',
      });
      expect(user.toJson()['email'], 'cut.meutia@mhs.unimal.ac.id');

      final menu = PublicMenuItem.fromJson({
        'id': 'm-1',
        'store_id': 's-1',
        'name': 'Mie Aceh Goreng Daging',
        'price': 22000,
        'store_name': 'Mie Aceh Bukit Indah',
        'rating_avg': 4.9,
        'sold_count': 42,
      });
      expect(menu.toJson()['store_id'], 's-1');
      expect(menu.price, 22000);

      final store = PublicStore.fromJson({
        'id': 's-1',
        'store_name': 'Mie Aceh Bukit Indah',
        'is_open': true,
        'menus': [
          {'id': 'm-1', 'store_id': 's-1', 'name': 'Mie Aceh', 'price': 18000},
        ],
      });
      expect(store.menus.length, 1);

      final promo = PromotionItem.fromJson({
        'id': 'p-1',
        'code': 'HEMAT10',
        'title': 'Diskon Mahasiswa',
        'discount_type': 'PERCENT',
        'discount_value': 10,
      });
      expect(promo.toJson()['code'], 'HEMAT10');

      final est = OrderEstimate.fromJson({
        'service_type': 'RIDE_MOTOR',
        'vehicle_type': 'MOTOR',
        'distance_km': 2.5,
        'delivery_fee': 10000,
        'total_customer_pay': 10000,
      });
      expect(est.totalCustomerPay, 10000);

      final order = CustomerOrder.fromJson({
        'id': 'o-1',
        'order_code': 'ORD-01',
        'service_type': 'FLEX_FOOD',
        'status': 'CREATED',
        'payment_method': 'QRIS',
        'total_customer_pay': 35000,
        'items': [
          {'menu_id': 'm-1', 'item_name': 'Mie Aceh', 'unit_price': 18000, 'qty': 1},
        ],
      });
      expect(order.toJson()['order_code'], 'ORD-01');
      expect(order.items.single.itemName, 'Mie Aceh');

      final qris = QrisPaymentResult.fromJson({
        'id': 'q-1',
        'reference_id': 'PAYG-123',
        'base_amount': 35000,
        'unique_code': 217,
        'payable_amount': 35217,
        'status': 'PAID',
      });
      expect(qris.isPaid, isTrue);

      final fav = UserFavorite.fromJson({
        'id': 'f-1',
        'user_id': 'u-1',
        'target_type': 'MENU',
        'menu_id': 'm-1',
      });
      expect(fav.menuId, 'm-1');
    });
  });

  group('CustomerApiService MockClient contracts', () {
    test('covers auth, catalog, favorites, estimate, order, qris, rating, ai & tickets', () async {
      final calls = <String>[];
      final mockClient = MockClient((req) async {
        calls.add('${req.method} ${req.url.path}');
        switch ('${req.method} ${req.url.path}') {
          case 'POST /v1/auth/login':
            return http.Response(
              jsonEncode({
                'token': 'jwt-customer-test',
                'user': {
                  'id': 'u-100',
                  'name': 'Cut Meutia',
                  'email': 'cut@rideons.app',
                  'phone': '628520001',
                  'role': 'CUSTOMER',
                  'status': 'ACTIVE',
                },
              }),
              200,
            );
          case 'PATCH /v1/auth/me':
            return http.Response(
              jsonEncode({
                'user': {
                  'id': 'u-100',
                  'name': 'Cut Meutia Updated',
                  'email': 'cut@rideons.app',
                  'phone': '628520001',
                },
              }),
              200,
            );
          case 'GET /v1/menus':
            return http.Response(
              jsonEncode({
                'menus': [
                  {
                    'id': 'menu-1',
                    'store_id': 'store-1',
                    'name': 'Mie Aceh',
                    'price': 20000,
                  },
                ],
              }),
              200,
            );
          case 'GET /v1/promotions':
            return http.Response(
              jsonEncode({
                'promotions': [
                  {'id': 'pr-1', 'code': 'UNIMAL', 'title': 'Promo Kampus'},
                ],
              }),
              200,
            );
          case 'POST /v1/favorites':
            return http.Response(jsonEncode({'id': 'fav-1'}), 201);
          case 'DELETE /v1/favorites/fav-1':
            return http.Response(jsonEncode({'deleted': true}), 200);
          case 'POST /v1/orders/estimate':
            return http.Response(
              jsonEncode({
                'service_type': 'RIDE_MOTOR',
                'vehicle_type': 'MOTOR',
                'total_customer_pay': 12000,
              }),
              200,
            );
          case 'POST /v1/orders':
            return http.Response(
              jsonEncode({
                'order': {
                  'id': 'ord-99',
                  'order_code': 'RDN-99',
                  'service_type': 'FLEX_FOOD',
                  'status': 'CREATED',
                  'payment_method': 'QRIS',
                  'total_customer_pay': 28000,
                },
              }),
              201,
            );
          case 'POST /pay/qris/generate':
            return http.Response(
              jsonEncode({
                'id': 'q-99',
                'reference_id': 'REF-99',
                'base_amount': 28000,
                'unique_code': 145,
                'payable_amount': 28145,
                'qris_payload': '000201010212',
                'status': 'PENDING',
              }),
              201,
            );
          case 'GET /pay/qris/REF-99/status':
            return http.Response(
              jsonEncode({
                'id': 'q-99',
                'reference_id': 'REF-99',
                'base_amount': 28000,
                'unique_code': 145,
                'payable_amount': 28145,
                'qris_payload': '000201010212',
                'status': 'PAID',
              }),
              200,
            );
          case 'POST /v1/orders/ord-99/rating':
            return http.Response(jsonEncode({'ok': true}), 200);
          case 'POST /ai/chat':
            return http.Response(
              jsonEncode({'reply': 'Coba Mie Aceh Daging Spesial kak!'}),
              200,
            );
          case 'POST /v1/support-tickets':
            return http.Response(jsonEncode({'id': 't-1'}), 201);
          default:
            return http.Response('{"error":"not found"}', 404);
        }
      });

      final api = CustomerApiService();
      api.resetForTest(client: mockClient);

      final auth = await api.login('cut@rideons.app', 'secret');
      expect(auth.token, 'jwt-customer-test');
      expect(api.hasSession, isTrue);

      final updated = await api.updateProfile(name: 'Cut Meutia Updated');
      expect(updated.name, 'Cut Meutia Updated');

      final menus = await api.getPublicMenus(query: 'Mie');
      expect(menus.single.name, 'Mie Aceh');

      final promos = await api.getPromotions();
      expect(promos.single.code, 'UNIMAL');

      final fav = await api.addFavorite(targetType: 'MENU', menuId: 'menu-1');
      expect(fav['id'], 'fav-1');
      await api.deleteFavorite('fav-1');

      final est = await api.estimateOrder(serviceType: 'RIDE_MOTOR');
      expect(est.totalCustomerPay, 12000);

      final order = await api.createOrder(
        serviceType: 'FLEX_FOOD',
        paymentMethod: 'QRIS',
        storeId: 'store-1',
        pickupAddress: 'Bukit Indah',
        dropoffAddress: 'Kampus Unimal',
      );
      expect(order.id, 'ord-99');

      final qris = await api.generateOrderQris(orderId: order.id, baseAmount: 28000);
      expect(qris.payableAmount, 28145);

      final status = await api.getQrisStatus('REF-99');
      expect(status.isPaid, isTrue);

      await api.submitRating(order.id, driverScore: 5, storeScore: 5);
      final aiReply = await api.aiChat(sessionId: 's1', message: 'rekomendasi');
      expect(aiReply, contains('Mie Aceh'));

      final ticket = await api.createSupportTicket(
        orderId: order.id,
        subject: 'Tes',
        bodyText: 'Bantuan order',
      );
      expect(ticket['id'], 't-1');
      expect(calls, containsAll(['POST /v1/auth/login', 'POST /pay/qris/generate', 'POST /ai/chat']));
    });
  });

  group('Stage 6 Widget Integrations', () {
    testWidgets('CheckoutView QRIS displays unique code & checks status', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var statusPaid = false;
      final mockClient = MockClient((req) async {
        if (req.url.path == '/v1/auth/login') {
          return http.Response(
            jsonEncode({
              'token': 'tok-qris',
              'user': {'id': 'u1', 'name': 'Cut', 'email': 'c@r.app', 'phone': '628'},
            }),
            200,
          );
        }
        if (req.url.path == '/v1/orders') {
          return http.Response(
            jsonEncode({
              'order': {
                'id': 'ord-qris-1',
                'service_type': 'FLEX_FOOD',
                'status': 'CREATED',
                'total_customer_pay': 35000,
              },
            }),
            201,
          );
        }
        if (req.url.path == '/pay/qris/generate') {
          return http.Response(
            jsonEncode({
              'id': 'q1',
              'reference_id': 'PAYG-01',
              'base_amount': 35000,
              'unique_code': 123,
              'payable_amount': 35123,
              'qris_payload': '000201QRIS_DEMO',
              'status': 'PENDING',
            }),
            201,
          );
        }
        if (req.url.path == '/pay/qris/PAYG-01/status') {
          return http.Response(
            jsonEncode({
              'id': 'q1',
              'reference_id': 'PAYG-01',
              'base_amount': 35000,
              'unique_code': 123,
              'payable_amount': 35123,
              'qris_payload': '000201QRIS_DEMO',
              'status': statusPaid ? 'PAID' : 'PENDING',
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final api = CustomerApiService();
      api.resetForTest(client: mockClient);
      await api.login('c@r.app', 'pass');

      String? createdOrderId;
      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutView(
            storeId: 'store-1',
            menuId: 'menu-1',
            onOrderCreated: (id) => createdOrderId = id,
            onBack: () {},
            onAddMoreItems: () {},
            onPlaceOrder: () {},
            cartQuantity: 1,
            subtotalPrice: 28000,
            spicyLevel: 2,
            extraEgg: false,
            kitchenNotes: '',
            deliveryFee: 5000,
            serviceFee: 2000,
            totalPrice: 35000,
          ),
        ),
      );

      await tester.ensureVisible(find.text('QRIS (Non-Tunai)'));
      await tester.tap(find.text('QRIS (Non-Tunai)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(createdOrderId, 'ord-qris-1');
      expect(find.text('Base: Rp 35000 • Kode Unik: +123'), findsOneWidget);
      expect(find.text('Transfer Tepat: Rp 35123'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_copy_qris_payload')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_check_qris_status')), findsOneWidget);

      statusPaid = true;
      await tester.ensureVisible(find.byKey(const ValueKey('btn_check_qris_status')));
      await tester.tap(find.byKey(const ValueKey('btn_check_qris_status')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Verifikasi Pembayaran Berhasil'), findsOneWidget);
    });

    testWidgets('ChatInboxView renders CS AI card and handles tap', (tester) async {
      var openedCs = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ChatInboxView(
            onOpenConversation: () {},
            onOpenCustomerService: () => openedCs = true,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('card_cs_ai_inbox')), findsOneWidget);
      expect(find.text('CS AI RideOn 24/7'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('card_cs_ai_inbox')));
      await tester.pumpAndSettle();
      expect(openedCs, isTrue);
    });

    testWidgets('BerandaScreen wisata tap navigates to FlexRideScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BerandaScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Gunung Rinjani'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Gunung Rinjani'));
      await tester.pumpAndSettle();

      expect(find.byType(FlexRideScreen), findsOneWidget);
    });
  });
}
