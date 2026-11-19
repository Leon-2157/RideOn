import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:driver_app/models/driver_model.dart';
import 'package:driver_app/models/order_model.dart';
import 'package:driver_app/models/wallet_model.dart';
import 'package:driver_app/services/driver_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DriverModel', () {
    test('fromJson parses complete user with nested driver profile', () {
      final json = {
        'id': 'user-001',
        'name': 'Zulkifli Hasan',
        'email': 'zulkifli.motor@rideons.app',
        'phone': '081234567890',
        'role': 'DRIVER',
        'status': 'ACTIVE',
        'driver': {
          'id': 'drv-001',
          'vehicle_type': 'MOTOR',
          'vehicle_brand': 'Honda Beat',
          'vehicle_plate': 'BL 1234 AB',
          'rating_avg': 4.85,
          'total_trips': 42,
          'is_online': true,
          'wallet_balance': 150000,
          'cash_float_amount': 200000,
        },
      };

      final model = DriverModel.fromJson(json);

      expect(model.id, 'user-001');
      expect(model.name, 'Zulkifli Hasan');
      expect(model.isActive, isTrue);
      expect(model.isPendingApproval, isFalse);
      expect(model.driver?.id, 'drv-001');
      expect(model.driver?.vehiclePlate, 'BL 1234 AB');
      expect(model.driver?.walletBalance, 150000);
    });

    test('isPendingApproval detects PENDING_APPROVAL', () {
      final model = DriverModel.fromJson({
        'id': 'u2',
        'name': 'New Driver',
        'email': 'new@rideons.app',
        'phone': '0852',
        'role': 'DRIVER',
        'status': 'PENDING_APPROVAL',
      });
      expect(model.isPendingApproval, isTrue);
      expect(model.isActive, isFalse);
    });
  });

  group('OrderModel canonical & legacy schemas', () {
    test('fromJson parses canonical rideon-api payload and items', () {
      final json = {
        'id': 'ord-101',
        'order_code': 'RO-2026-0001',
        'service_type': 'FLEX_FOOD',
        'status': 'SEARCHING_DRIVER',
        'payment_method': 'QRIS',
        'payment_status': 'PAID',
        'customer_name': 'Fikri Ramadhan',
        'customer_phone': '085211112222',
        'pickup_address': 'Mie Aceh Bukit Indah',
        'dropoff_address': 'Jl. Dumai, Lhokseumawe',
        'store_name': 'Mie Aceh Bukit Indah',
        'subtotal_items': 50000,
        'delivery_fee': 12000,
        'total_customer_pay': 62000,
        'distance_km': 3.5,
        'platform_commission_driver': 600,
        'driver_net_earning': 11400,
        'created_at': '2026-11-19T10:00:00Z',
        'items': [
          {'item_name': 'Mie Aceh Goreng', 'qty': 2, 'unit_price': 25000},
        ],
      };

      final order = OrderModel.fromJson(json);

      expect(order.id, 'ord-101');
      expect(order.orderCode, 'RO-2026-0001');
      expect(order.isFlexFood, isTrue);
      expect(order.isSearchingDriver, isTrue);
      expect(order.deliveryAddress, 'Jl. Dumai, Lhokseumawe');
      expect(order.totalPrice, 62000);
      expect(order.driverCommission, 600);
      expect(order.driverNetEarning, 11400);
      expect(order.items.length, 1);
      expect(order.items.first.name, 'Mie Aceh Goreng');
      expect(order.items.first.qty, 2);
    });

    test('fromJson handles completed and legacy keys', () {
      final order = OrderModel.fromJson({
        'id': 'ord-102',
        'service_type': 'FLEXFOOD',
        'status': 'COMPLETE',
        'delivery_address': 'Jl. Merdeka',
        'total_price': 45000,
        'driver_commission': 2250,
      });
      expect(order.isFlexFood, isTrue);
      expect(order.isCompleted, isTrue);
      expect(order.deliveryAddress, 'Jl. Merdeka');
      expect(order.totalPrice, 45000);
      expect(order.driverCommission, 2250);
    });
  });

  group('WalletModel, WalletTransaction & QrisTopUpResult', () {
    test('WalletModel withdraw & negative limit boundaries', () {
      const ok = WalletModel(
        id: 'w1',
        ownerType: 'DRIVER',
        ownerId: 'd1',
        balance: 20000,
        bankName: 'BSI',
        bankAccountNumber: '123',
        bankAccountHolder: 'Zulkifli',
      );
      expect(ok.canWithdraw, isTrue);
      expect(ok.isNegative, isFalse);

      const neg = WalletModel(
        id: 'w2',
        ownerType: 'DRIVER',
        ownerId: 'd1',
        balance: -20000,
        bankName: 'BSI',
        bankAccountNumber: '123',
        bankAccountHolder: 'Zulkifli',
      );
      expect(neg.canWithdraw, isFalse);
      expect(neg.isNegative, isTrue);
      expect(neg.isAtNegativeLimit, isTrue);
    });

    test('WalletTransaction maps canonical tx_type & QrisTopUpResult parses unique_code', () {
      final credit = WalletTransaction.fromJson({
        'id': 'tx1',
        'tx_type': 'ORDER_EARNING',
        'amount': 11400,
        'balance_before': 0,
        'balance_after': 11400,
        'reference_id': 'ord-1',
        'description': 'Pendapatan order',
        'created_at': '2026-11-19T10:00:00Z',
      });
      expect(credit.isCredit, isTrue);
      expect(credit.category, 'Pendapatan');

      final commission = WalletTransaction.fromJson({
        'id': 'tx2',
        'tx_type': 'COMMISSION_DEBIT',
        'amount': -600,
        'balance_after': 10800,
        'description': 'Potongan komisi 5%',
        'created_at': '2026-11-19T10:00:00Z',
      });
      expect(commission.isCredit, isFalse);
      expect(commission.category, 'Fee admin');

      final qris = QrisTopUpResult.fromJson({
        'id': 'q1',
        'reference_id': 'TOPUP-123',
        'base_amount': 50000,
        'unique_code': 618,
        'payable_amount': 50618,
        'qris_payload': '000201010212...',
        'qr_svg': '<svg></svg>',
        'status': 'PENDING',
        'expires_at': '2026-11-19T12:00:00Z',
      });
      expect(qris.uniqueCode, 618);
      expect(qris.payableAmount, 50618);
      expect(qris.qrSvg, contains('<svg>'));
    });
  });

  group('DriverApiService contract tests with MockClient', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('login stores separate user_id and driver_id', () async {
      final mock = MockClient((req) async {
        expect(req.url.path, '/v1/auth/login');
        return http.Response(
          jsonEncode({
            'token': 'jwt-test',
            'user': {
              'id': '0000-user-id',
              'name': 'Zulkifli',
              'email': 'z@rideons.app',
              'phone': '62852',
              'role': 'DRIVER',
              'status': 'ACTIVE',
              'driver': {
                'id': '1000-driver-id',
                'vehicle_type': 'MOTOR',
                'vehicle_brand': 'Beat',
                'vehicle_plate': 'BL 1234',
                'rating_avg': 4.9,
                'total_trips': 5,
                'is_online': false,
                'wallet_balance': 50000,
                'cash_float_amount': 200000,
              },
            },
          }),
          200,
        );
      });

      final api = DriverApiService();
      api.resetForTest(client: mock);

      final res = await api.login('z@rideons.app', 'RideOnDemo2026!');
      expect(res.user.id, '0000-user-id');
      expect(await api.getSavedUserId(), '0000-user-id');
      expect(await api.getSavedDriverId(), '1000-driver-id');
      expect(api.hasSession, isTrue);
    });

    test('updateDriverStatus surfaces 403 for PENDING_APPROVAL', () async {
      final mock = MockClient((req) async {
        expect(req.method, 'PATCH');
        expect(req.url.path, '/v1/drivers/drv-pending/status');
        return http.Response(
          jsonEncode({'error': 'Akun menunggu persetujuan admin'}),
          403,
        );
      });

      final api = DriverApiService();
      api.resetForTest(client: mock);

      expect(
        () => api.updateDriverStatus('drv-pending', isOnline: true),
        throwsA(isA<ApiException>().having((e) => e.isForbidden, '403', isTrue)),
      );
    });

    test('acceptOrder surfaces 409 ORDER_ALREADY_TAKEN', () async {
      final mock = MockClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/v1/orders/ord-9/accept-driver');
        return http.Response(
          jsonEncode({'error': 'ORDER_ALREADY_TAKEN'}),
          409,
        );
      });

      final api = DriverApiService();
      api.resetForTest(client: mock);

      expect(
        () => api.acceptOrder('ord-9'),
        throwsA(isA<ApiException>().having((e) => e.isConflict, '409', isTrue)),
      );
    });

    test('requestWithdrawal, generateTopUpQris, and aiChat send expected payloads', () async {
      final paths = <String>[];
      final mock = MockClient((req) async {
        paths.add(req.url.path);
        final body = req.body.isNotEmpty
            ? jsonDecode(req.body) as Map<String, dynamic>
            : <String, dynamic>{};

        if (req.url.path == '/v1/withdrawals') {
          expect(body['owner_type'], 'DRIVER');
          expect(body['owner_id'], 'drv-1');
          expect(body['amount'], 50000);
          return http.Response(jsonEncode({'id': 'wd-1', 'status': 'PENDING'}), 201);
        }
        if (req.url.path == '/pay/qris/generate') {
          expect(body['purpose'], 'DRIVER_TOPUP');
          expect(body['base_amount'], 50000);
          return http.Response(
            jsonEncode({
              'id': 'q-1',
              'reference_id': 'TOPUP-1',
              'base_amount': 50000,
              'unique_code': 421,
              'payable_amount': 50421,
              'qris_payload': '000201...',
              'qr_svg': '<svg/>',
              'status': 'PENDING',
              'expires_at': '2026-11-19T12:00:00Z',
            }),
            200,
          );
        }
        if (req.url.path == '/ai/chat') {
          expect(body['app_role'], 'DRIVER');
          expect(body['message'], 'Halo CS');
          return http.Response(jsonEncode({'reply': 'Siap membantu!'}), 200);
        }
        return http.Response('{}', 404);
      });

      final api = DriverApiService();
      api.resetForTest(client: mock);

      await api.requestWithdrawal(
        driverId: 'drv-1',
        userId: 'usr-1',
        amount: 50000,
        bankName: 'BSI',
        bankAccountNumber: '88201928',
        bankAccountHolder: 'Zulkifli',
      );
      final qris = await api.generateTopUpQris(baseAmount: 50000, userId: 'usr-1');
      final reply = await api.aiChat(
        sessionId: 'sess-1',
        message: 'Halo CS',
        userId: 'usr-1',
      );

      expect(qris.payableAmount, 50421);
      expect(reply, 'Siap membantu!');
      expect(paths, ['/v1/withdrawals', '/pay/qris/generate', '/ai/chat']);
    });
  });
}
