import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_toko/models/menu_model.dart';
import 'package:page_toko/models/store_model.dart';
import 'package:page_toko/models/store_order_model.dart';
import 'package:page_toko/models/store_wallet_model.dart';
import 'package:page_toko/services/toko_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TokoApiService.enableLocalFallback = false;
    await TokoApiService().logout();
  });

  tearDown(() {
    TokoApiService().clientOverride = null;
  });

  group('Toko Models', () {
    test('StoreUser parses store nested payload and PENDING_APPROVAL', () {
      final user = StoreUser.fromJson({
        'id': 'u-store-1',
        'name': 'Bang Zulkarnain',
        'email': 'mieaceh.bukitindah@rideons.app',
        'phone': '6285260000301',
        'role': 'STORE',
        'status': 'PENDING_APPROVAL',
        'avatar_url': '',
        'store': {
          'id': '20000000-0000-4000-8000-000000000301',
          'store_name': 'Mie Aceh & Martabak Bukit Indah',
          'category': 'Kuliner Aceh',
          'description': 'Mie Aceh autentik',
          'address': 'Bukit Indah, Lhokseumawe',
          'lat': 5.2041,
          'lng': 97.0638,
          'is_open': false,
          'open_time': '08:00',
          'close_time': '22:00',
          'rating_avg': 4.9,
          'wallet_balance': 500000,
        },
      });
      expect(user.isPendingApproval, isTrue);
      expect(user.isActive, isFalse);
      expect(user.store?.id, '20000000-0000-4000-8000-000000000301');
      expect(user.store?.storeName, 'Mie Aceh & Martabak Bukit Indah');
    });

    test('StoreOrderModel maps all 4 status tab buckets accurately', () {
      StoreOrderModel mk(String status) => StoreOrderModel.fromJson({
            'id': 'o1',
            'order_code': 'ORD-111',
            'status': status,
            'customer_name': 'Cut Meutia',
            'items_subtotal': 30000,
            'items': [
              {'id': 'i1', 'item_name': 'Mie Aceh Spesial', 'qty': 2, 'unit_price': 15000, 'subtotal': 30000},
            ],
          });

      expect(mk('WAITING_STORE_CONFIRM').tabBucket, 'baru');
      expect(mk('SEARCHING_DRIVER').tabBucket, 'diproses');
      expect(mk('IN_TRANSIT').tabBucket, 'diproses');
      expect(mk('COMPLETED').tabBucket, 'selesai');
      expect(mk('CANCELLED').tabBucket, 'batal');
      expect(mk('WAITING_STORE_CONFIRM').toScreenMap()['items'], '2× Mie Aceh Spesial');
    });

    test('StoreMenuModel & StoreWalletModel parse JSON cleanly', () {
      final menu = StoreMenuModel.fromJson({
        'id': 'm-1',
        'store_id': 's-1',
        'name': 'Martabak Telor',
        'category': 'Makanan Utama',
        'price': 22000,
        'description': 'Martabak garing kari Aceh',
        'is_available': true,
      });
      expect(menu.toScreenMap()['price'], 22000);
      expect(menu.toJson()['is_available'], isTrue);

      final wallet = StoreWalletModel.fromJson({
        'wallet': {
          'id': 'w-1',
          'owner_type': 'STORE',
          'owner_id': 's-1',
          'balance': 450000,
          'transactions': [
            {
              'id': 'tx-1',
              'tx_type': 'ORDER_EARNING',
              'amount': 38000,
              'balance_before': 412000,
              'balance_after': 450000,
              'description': 'Penjualan Menu FlexFood QRIS',
              'created_at': '2026-11-19T05:00:00Z',
            },
          ],
        },
      });
      expect(wallet.balance, 450000);
      expect(wallet.transactions.length, 1);
      expect(wallet.transactions.first.isCredit, isTrue);
    });
  });

  group('TokoApiService HTTP contracts', () {
    test('login saves store_id and enforces 403 on pending open toggle', () async {
      final api = TokoApiService();
      api.clientOverride = MockClient((req) async {
        if (req.url.path == '/v1/auth/login') {
          return http.Response(
            jsonEncode({
              'token': 'jwt-store-token',
              'user': {
                'id': 'u-301',
                'name': 'Pemilik Mie Aceh',
                'email': 'mieaceh.bukitindah@rideons.app',
                'phone': '6285260000301',
                'role': 'STORE',
                'status': 'ACTIVE',
                'store': {
                  'id': '20000000-0000-4000-8000-000000000301',
                  'store_name': 'Mie Aceh Bukit Indah',
                  'is_open': true,
                },
              },
            }),
            200,
          );
        }
        if (req.url.path == '/v1/stores/20000000-0000-4000-8000-000000000301/status' &&
            req.method == 'PATCH') {
          return http.Response(jsonEncode({'error': 'Akun toko masih pending'}), 403);
        }
        if (req.url.path == '/v1/withdrawals' && req.method == 'POST') {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          if (body['pin'] != '123456') {
            return http.Response(jsonEncode({'error': 'PIN salah'}), 401);
          }
          return http.Response(jsonEncode({'id': 'wd-1', 'status': 'PENDING'}), 201);
        }
        if (req.url.path == '/ai/chat') {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          expect(body['app_role'], 'STORE');
          return http.Response(jsonEncode({'reply': 'Mie Aceh hangat penuh rempah.'}), 200);
        }
        return http.Response('{}', 404);
      });

      final user = await api.login('mieaceh.bukitindah@rideons.app', 'RideOnDemo2026!');
      expect(user.store?.id, '20000000-0000-4000-8000-000000000301');
      expect(api.savedStoreId, '20000000-0000-4000-8000-000000000301');

      await expectLater(
        () => api.setStoreOpenStatus(user.store!.id, true),
        throwsA(isA<TokoApiException>().having((e) => e.statusCode, 'statusCode', 403)),
      );

      final wd = await api.requestWithdrawal(
        storeId: user.store!.id,
        amount: 50000,
        bankName: 'BSI',
        accountNumber: '7123456789',
        accountName: 'Pemilik',
        pin: '123456',
      );
      expect(wd['status'], 'PENDING');

      final aiReply = await api.aiChat(sessionId: 's1', message: 'Buat deskripsi');
      expect(aiReply, contains('Mie Aceh'));
    });
  });
}

