import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/driver_model.dart';
import '../models/order_model.dart';
import '../models/wallet_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  bool get isForbidden => statusCode == 403;
  bool get isConflict => statusCode == 409;

  @override
  String toString() =>
      'ApiException($statusCode): $message';
}

/// REST client for `rideon-api`, `payg`, and `ai-service` behind Nginx (`:8088`).
class DriverApiService {
  static final DriverApiService _instance = DriverApiService._();
  factory DriverApiService() => _instance;
  DriverApiService._();

  /// Test-only switch allowing legacy UI widget tests without network to proceed.
  static bool enableLocalFallback = false;

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const List<String> _fallbackUrls = [
    'http://10.0.2.2:8088',
    'http://127.0.0.1:8088',
    'http://localhost:8088',
    'https://api.rideons.app',
  ];

  static const String _kToken = 'driver_jwt_token';
  static const String _kUserId = 'driver_user_id';
  static const String _kDriverId = 'driver_profile_id';
  static const String _kUserName = 'driver_user_name';
  static const String _kUserStatus = 'driver_user_status';
  static const String _kVehicleType = 'driver_vehicle_type';
  static const Duration _timeout = Duration(seconds: 10);

  http.Client? clientOverride;
  String? _resolvedBaseUrl;
  String? _token;
  String? _userId;
  String? _driverId;
  String? _userName;
  String? _userStatus;
  String? _vehicleType;

  bool get hasSession => (_token ?? '').isNotEmpty;
  String? get cachedUserId => _userId;
  String? get cachedDriverId => _driverId;
  String? get cachedUserName => _userName;
  String? get cachedUserStatus => _userStatus;
  String? get cachedVehicleType => _vehicleType;

  List<String> get _baseCandidates {
    final list = <String>[];
    if (_envBaseUrl.isNotEmpty) list.add(_envBaseUrl);
    if (_resolvedBaseUrl != null && !list.contains(_resolvedBaseUrl)) {
      list.add(_resolvedBaseUrl!);
    }
    for (final url in _fallbackUrls) {
      if (!list.contains(url)) list.add(url);
    }
    return list;
  }

  String resolveUrl(String path) {
    if (path.isEmpty || path.startsWith('http')) return path;
    final base = _resolvedBaseUrl ??
        (_envBaseUrl.isNotEmpty ? _envBaseUrl : _fallbackUrls.first);
    return path.startsWith('/') ? '$base$path' : '$base/$path';
  }

  /// Clears in-memory and mock-override state for isolated unit/widget tests.
  void resetForTest({http.Client? client}) {
    clientOverride = client;
    _resolvedBaseUrl = 'http://127.0.0.1:8088';
    _token = null;
    _userId = null;
    _driverId = null;
    _userName = null;
    _userStatus = null;
    _vehicleType = null;
  }

  /// Hydrates cached JWT and profile fields from SharedPreferences.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _userId = prefs.getString(_kUserId);
    _driverId = prefs.getString(_kDriverId);
    _userName = prefs.getString(_kUserName);
    _userStatus = prefs.getString(_kUserStatus);
    _vehicleType = prefs.getString(_kVehicleType);
  }

  Future<bool> hasSavedSession() async {
    if (hasSession) return true;
    await restoreSession();
    return hasSession;
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    await restoreSession();
    return _token;
  }

  Future<String?> getSavedUserId() async {
    if (_userId != null) return _userId;
    await restoreSession();
    return _userId;
  }

  Future<String?> getSavedDriverId() async {
    if (_driverId != null) return _driverId;
    await restoreSession();
    return _driverId;
  }

  Future<String?> getSavedDriverStatus() async {
    if (_userStatus != null) return _userStatus;
    await restoreSession();
    return _userStatus;
  }

  Future<String?> getSavedDriverName() async {
    if (_userName != null) return _userName;
    await restoreSession();
    return _userName;
  }

  Future<String?> getSavedVehicleType() async {
    if (_vehicleType != null) return _vehicleType;
    await restoreSession();
    return _vehicleType;
  }

  Future<void> _persistSession({
    String? token,
    required DriverModel user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null && token.isNotEmpty) {
      _token = token;
      await prefs.setString(_kToken, token);
    }
    _userId = user.id;
    _userName = user.name;
    _userStatus = user.status;
    await prefs.setString(_kUserId, user.id);
    await prefs.setString(_kUserName, user.name);
    await prefs.setString(_kUserStatus, user.status);

    final d = user.driver;
    if (d != null && d.id.isNotEmpty) {
      _driverId = d.id;
      _vehicleType = d.vehicleType;
      await prefs.setString(_kDriverId, d.id);
      await prefs.setString(_kVehicleType, d.vehicleType);
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _driverId = null;
    _userName = null;
    _userStatus = null;
    _vehicleType = null;
    final prefs = await SharedPreferences.getInstance();
    for (final k in const [
      _kToken,
      _kUserId,
      _kDriverId,
      _kUserName,
      _kUserStatus,
      _kVehicleType,
    ]) {
      await prefs.remove(k);
    }
  }

  Future<Map<String, String>> _headers() async {
    final t = await getToken();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  Map<String, dynamic> _decodeJson(http.Response res) {
    final decoded =
        res.body.isNotEmpty ? jsonDecode(res.body) : <String, dynamic>{};
    final map = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = (map['error'] ?? map['message'] ?? 'HTTP ${res.statusCode}')
          .toString();
      throw ApiException(msg, res.statusCode);
    }
    return map;
  }

  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _headers();
    final encoded = body != null ? jsonEncode(body) : null;
    final candidates =
        clientOverride != null ? [_baseCandidates.first] : _baseCandidates;

    Object? lastNetworkError;
    for (final base in candidates) {
      final uri = Uri.parse('$base$path');
      try {
        final client = clientOverride ?? http.Client();
        try {
          late final http.Response res;
          switch (method) {
            case 'GET':
              res = await client.get(uri, headers: headers).timeout(_timeout);
              break;
            case 'POST':
              res = await client
                  .post(uri, headers: headers, body: encoded)
                  .timeout(_timeout);
              break;
            case 'PATCH':
              res = await client
                  .patch(uri, headers: headers, body: encoded)
                  .timeout(_timeout);
              break;
            case 'PUT':
              res = await client
                  .put(uri, headers: headers, body: encoded)
                  .timeout(_timeout);
              break;
            case 'DELETE':
              res =
                  await client.delete(uri, headers: headers).timeout(_timeout);
              break;
            default:
              throw ArgumentError('Unsupported HTTP method: $method');
          }
          _resolvedBaseUrl = base;
          return _decodeJson(res);
        } finally {
          if (clientOverride == null) client.close();
        }
      } on ApiException {
        rethrow;
      } catch (e) {
        lastNetworkError = e;
        debugPrint('[DriverApiService] $method $uri failed: $e');
      }
    }
    throw ApiException('Server tidak dapat dijangkau ($lastNetworkError)');
  }

  // --- Auth & Registration ---

  Future<({String token, DriverModel user})> login(
    String identifier,
    String password,
  ) async {
    final data = await _requestJson(
      'POST',
      '/v1/auth/login',
      body: {'identifier': identifier, 'password': password},
    );
    final token = (data['token'] ?? '').toString();
    final userMap = data['user'] as Map<String, dynamic>? ?? {};
    final user = DriverModel.fromJson(userMap);
    await _persistSession(token: token, user: user);
    return (token: token, user: user);
  }

  Future<DriverModel> getMe() async {
    final data = await _requestJson('GET', '/v1/auth/me');
    final user = DriverModel.fromJson(data['user'] as Map<String, dynamic>);
    await _persistSession(user: user);
    return user;
  }

  Future<Map<String, dynamic>> sendOtp({
    required String target,
    String channel = 'WHATSAPP',
    String purpose = 'REGISTER',
  }) {
    return _requestJson(
      'POST',
      '/v1/auth/otp/send',
      body: {'target': target, 'channel': channel, 'purpose': purpose},
    );
  }

  Future<bool> verifyOtp({
    required String target,
    String channel = 'WHATSAPP',
    required String code,
  }) async {
    final data = await _requestJson(
      'POST',
      '/v1/auth/otp/verify',
      body: {'target': target, 'channel': channel, 'code': code},
    );
    return data['verified'] == true || data['success'] == true;
  }

  Future<String> uploadDocument(
    String filePath, {
    String category = 'driver_doc',
  }) async {
    final token = await getToken();
    final candidates =
        clientOverride != null ? [_baseCandidates.first] : _baseCandidates;

    Object? lastErr;
    for (final base in candidates) {
      final uri = Uri.parse('$base/v1/upload');
      try {
        final req = http.MultipartRequest('POST', uri);
        req.fields['category'] = category;
        if (token != null && token.isNotEmpty) {
          req.headers['Authorization'] = 'Bearer $token';
        }
        req.files.add(await http.MultipartFile.fromPath('file', filePath));
        final streamed = clientOverride != null
            ? await clientOverride!.send(req).timeout(_timeout)
            : await req.send().timeout(_timeout);
        final res = await http.Response.fromStream(streamed);
        final data = _decodeJson(res);
        _resolvedBaseUrl = base;
        return (data['url'] ?? data['full_url'] ?? '').toString();
      } on ApiException {
        rethrow;
      } catch (e) {
        lastErr = e;
      }
    }
    throw ApiException('Gagal upload file ($lastErr)');
  }

  Future<Map<String, dynamic>> registerDriver({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String vehicleType,
    required String vehicleBrand,
    required String vehiclePlate,
    String? ktpNumber,
    String? simNumber,
    String? ktpPhotoUrl,
    String? simPhotoUrl,
    String? stnkPhotoUrl,
  }) async {
    final body = <String, dynamic>{
      'role': 'DRIVER',
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'vehicle_type': vehicleType,
      'vehicle_brand': vehicleBrand,
      'vehicle_plate': vehiclePlate,
    };
    if (ktpNumber != null && ktpNumber.isNotEmpty) body['ktp_number'] = ktpNumber;
    if (simNumber != null && simNumber.isNotEmpty) body['sim_number'] = simNumber;
    if (ktpPhotoUrl != null && ktpPhotoUrl.isNotEmpty) {
      body['ktp_photo_url'] = ktpPhotoUrl;
    }
    if (simPhotoUrl != null && simPhotoUrl.isNotEmpty) {
      body['sim_photo_url'] = simPhotoUrl;
    }
    if (stnkPhotoUrl != null && stnkPhotoUrl.isNotEmpty) {
      body['stnk_photo_url'] = stnkPhotoUrl;
    }

    final data = await _requestJson('POST', '/v1/auth/register', body: body);
    if (data['user'] is Map<String, dynamic>) {
      await _persistSession(
        token: data['token']?.toString(),
        user: DriverModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    }
    return data;
  }

  // --- Driver Status & Radar ---

  Future<DriverInfo> updateDriverStatus(
    String driverId, {
    bool? isOnline,
    int? cashFloatAmount,
    double? lastLat,
    double? lastLng,
  }) async {
    final body = <String, dynamic>{};
    if (isOnline != null) body['is_online'] = isOnline;
    if (cashFloatAmount != null) body['cash_float_amount'] = cashFloatAmount;
    if (lastLat != null) body['last_lat'] = lastLat;
    if (lastLng != null) body['last_lng'] = lastLng;

    final data = await _requestJson(
      'PATCH',
      '/v1/drivers/$driverId/status',
      body: body,
    );
    final driverMap = data['driver'] as Map<String, dynamic>? ?? data;
    return DriverInfo.fromJson(driverMap);
  }

  Future<DriverInfo> setOnlineStatus(String driverId, bool isOnline) {
    return updateDriverStatus(driverId, isOnline: isOnline);
  }

  // --- Orders & Trips ---

  Future<List<OrderModel>> getOrders({
    String? status,
    String? driverId,
    bool available = false,
    String? vehicleType,
  }) async {
    final params = <String, String>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (driverId != null && driverId.isNotEmpty) params['driver_id'] = driverId;
    if (available) params['available'] = 'true';
    if (vehicleType != null && vehicleType.isNotEmpty) {
      params['vehicle_type'] = vehicleType;
    }

    final query = Uri(queryParameters: params).query;
    final path = query.isNotEmpty ? '/v1/orders?$query' : '/v1/orders';
    final data = await _requestJson('GET', path);
    final raw = data['orders'] as List? ?? [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
  }

  Future<List<OrderModel>> getAvailableOrders({String? vehicleType}) {
    return getOrders(
      status: 'SEARCHING_DRIVER',
      available: true,
      vehicleType: vehicleType,
    );
  }

  Future<List<OrderModel>> getDriverHistoryOrders(
    String driverId, {
    String status = 'COMPLETED,CANCELLED',
  }) {
    return getOrders(driverId: driverId, status: status);
  }

  Future<OrderModel> getOrder(String orderId) async {
    final data = await _requestJson('GET', '/v1/orders/$orderId');
    final map = data['order'] as Map<String, dynamic>? ?? data;
    return OrderModel.fromJson(map);
  }

  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    final driverId = await getSavedDriverId();
    final body = <String, dynamic>{};
    if (driverId != null && driverId.isNotEmpty) body['driver_id'] = driverId;
    return _requestJson('POST', '/v1/orders/$orderId/accept-driver', body: body);
  }

  Future<void> rejectOrder(String orderId) async {
    final driverId = await getSavedDriverId();
    final body = <String, dynamic>{};
    if (driverId != null && driverId.isNotEmpty) body['driver_id'] = driverId;
    await _requestJson('POST', '/v1/orders/$orderId/driver-reject', body: body);
  }

  Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String status,
  ) {
    return _requestJson(
      'POST',
      '/v1/orders/$orderId/status',
      body: {'status': status},
    );
  }

  Future<Map<String, dynamic>> submitFlexSendReceipt(
    String orderId, {
    required int talanganActualAmount,
    required int parkingFee,
    String? receiptPhotoUrl,
    String? parkingPhotoUrl,
  }) {
    final body = <String, dynamic>{
      'talangan_actual_amount': talanganActualAmount,
      'parking_fee': parkingFee,
    };
    if (receiptPhotoUrl != null && receiptPhotoUrl.isNotEmpty) {
      body['receipt_photo_url'] = receiptPhotoUrl;
    }
    if (parkingPhotoUrl != null && parkingPhotoUrl.isNotEmpty) {
      body['parking_photo_url'] = parkingPhotoUrl;
    }
    return _requestJson(
      'POST',
      '/v1/orders/$orderId/flexsend-receipt',
      body: body,
    );
  }

  Future<Map<String, dynamic>> completeOrder(String orderId) {
    return _requestJson('POST', '/v1/orders/$orderId/complete', body: {});
  }

  // --- Wallet, Withdrawals & Top-Up QRIS ---

  Future<({WalletModel wallet, List<WalletTransaction> transactions})>
      getWalletWithTransactions(String driverId) async {
    final data = await _requestJson('GET', '/v1/wallets/DRIVER/$driverId');
    final walletMap = data['wallet'] as Map<String, dynamic>? ?? {};
    final rawTx = (walletMap['transactions'] as List?) ??
        (data['transactions'] as List?) ??
        const [];
    return (
      wallet: WalletModel.fromJson(walletMap),
      transactions: rawTx
          .whereType<Map<String, dynamic>>()
          .map(WalletTransaction.fromJson)
          .toList(),
    );
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required String driverId,
    String? userId,
    required int amount,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountHolder,
  }) async {
    final uid = userId ?? await getSavedUserId() ?? '';
    final body = <String, dynamic>{
      'owner_type': 'DRIVER',
      'owner_id': driverId,
      'requester_user_id': uid,
      'amount': amount,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_holder': bankAccountHolder,
    };
    return _requestJson('POST', '/v1/withdrawals', body: body);
  }

  Future<QrisTopUpResult> generateTopUpQris({
    required int baseAmount,
    String? userId,
  }) async {
    final uid = userId ?? await getSavedUserId() ?? '';
    final data = await _requestJson(
      'POST',
      '/pay/qris/generate',
      body: {
        'purpose': 'DRIVER_TOPUP',
        'user_id': uid,
        'base_amount': baseAmount,
        'amount': baseAmount,
      },
    );
    return QrisTopUpResult.fromJson(data);
  }

  Future<QrisTopUpResult> getQrisStatus(String referenceId) async {
    final data = await _requestJson('GET', '/pay/qris/$referenceId/status');
    return QrisTopUpResult.fromJson(data);
  }

  // --- Talangan Claims & Support ---

  Future<Map<String, dynamic>> submitTalanganClaim({
    required String orderId,
    required String driverId,
    required int claimedAmount,
    required String goodsPhotoUrl,
    required String receiptPhotoUrl,
  }) {
    return _requestJson(
      'POST',
      '/v1/talangan-claims',
      body: {
        'order_id': orderId,
        'driver_id': driverId,
        'claimed_amount': claimedAmount,
        'goods_photo_url': goodsPhotoUrl,
        'receipt_photo_url': receiptPhotoUrl,
      },
    );
  }

  Future<Map<String, dynamic>> submitTalanganDonation({
    required String claimId,
    required String orphanageName,
    required String donationPhotoUrl,
  }) {
    return _requestJson(
      'POST',
      '/v1/talangan-claims/$claimId/donate',
      body: {
        'orphanage_name': orphanageName,
        'donation_photo_url': donationPhotoUrl,
      },
    );
  }

  Future<Map<String, dynamic>> createSupportTicket({
    String? userId,
    String? orderId,
    String channel = 'IN_APP',
    required String subject,
    required String body,
  }) async {
    final uid = userId ?? await getSavedUserId();
    final payload = <String, dynamic>{
      'channel': channel,
      'subject': subject,
      'body': body,
    };
    if (uid != null && uid.isNotEmpty) payload['user_id'] = uid;
    if (orderId != null && orderId.isNotEmpty) payload['order_id'] = orderId;
    return _requestJson('POST', '/v1/support-tickets', body: payload);
  }

  // --- AI Service ---

  Future<String> aiChat({
    required String sessionId,
    required String message,
    String? systemPrompt,
    String? userId,
  }) async {
    final uid = userId ?? await getSavedUserId();
    final body = <String, dynamic>{
      'session_id': sessionId,
      'app_role': 'DRIVER',
      'message': message,
    };
    if (uid != null && uid.isNotEmpty) body['user_id'] = uid;
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['system_prompt'] = systemPrompt;
    }

    final data = await _requestJson('POST', '/ai/chat', body: body);
    return (data['reply'] ?? data['message'] ?? data['content'] ?? '')
        .toString();
  }
}
