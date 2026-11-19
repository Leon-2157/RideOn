import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer_models.dart';

class CustomerApiException implements Exception {
  final String message;
  final int? statusCode;

  CustomerApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'CustomerApiException($statusCode): $message';
}

/// REST client for `rideon-api`, `payg`, and `ai-service` behind Nginx (`:8088`).
class CustomerApiService {
  static final CustomerApiService _instance = CustomerApiService._();
  factory CustomerApiService() => _instance;
  CustomerApiService._();

  /// Test-only switch preserving deterministic offline widget test behavior.
  static bool enableLocalFallback = false;

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const List<String> _fallbackUrls = [
    'http://10.0.2.2:8088',
    'http://127.0.0.1:8088',
    'http://localhost:8088',
    'https://api.rideons.app',
  ];

  static const String _kToken = 'customer_jwt_token';
  static const String _kUserId = 'customer_user_id';
  static const String _kUserName = 'customer_user_name';
  static const String _kUserEmail = 'customer_user_email';
  static const String _kUserPhone = 'customer_user_phone';
  static const String _kAvatarUrl = 'customer_avatar_url';
  static const Duration _timeout = Duration(seconds: 10);

  http.Client? clientOverride;
  String? _resolvedBaseUrl;
  String? _token;
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _avatarUrl;

  bool get hasSession => (_token ?? '').isNotEmpty;
  String? get cachedUserId => _userId;
  String? get cachedUserName => _userName;
  String? get cachedUserEmail => _userEmail;
  String? get cachedUserPhone => _userPhone;
  String? get cachedAvatarUrl => _avatarUrl;

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

  /// Resets in-memory state and optionally injects a mock `http.Client` for tests.
  void resetForTest({http.Client? client}) {
    clientOverride = client;
    _resolvedBaseUrl = 'http://127.0.0.1:8088';
    _token = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userPhone = null;
    _avatarUrl = null;
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _userId = prefs.getString(_kUserId);
    _userName = prefs.getString(_kUserName);
    _userEmail = prefs.getString(_kUserEmail);
    _userPhone = prefs.getString(_kUserPhone);
    _avatarUrl = prefs.getString(_kAvatarUrl);
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    await restoreSession();
    return _token;
  }

  Future<void> _persistSession({
    String? token,
    required CustomerUser user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null && token.isNotEmpty) {
      _token = token;
      await prefs.setString(_kToken, token);
    }
    _userId = user.id;
    _userName = user.name;
    _userEmail = user.email;
    _userPhone = user.phone;
    _avatarUrl = user.avatarUrl;
    await prefs.setString(_kUserId, user.id);
    await prefs.setString(_kUserName, user.name);
    await prefs.setString(_kUserEmail, user.email);
    await prefs.setString(_kUserPhone, user.phone);
    await prefs.setString(_kAvatarUrl, user.avatarUrl);
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userPhone = null;
    _avatarUrl = null;
    final prefs = await SharedPreferences.getInstance();
    for (final k in const [
      _kToken,
      _kUserId,
      _kUserName,
      _kUserEmail,
      _kUserPhone,
      _kAvatarUrl,
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
      throw CustomerApiException(msg, res.statusCode);
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

    Object? lastErr;
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
      } on CustomerApiException {
        rethrow;
      } catch (e) {
        lastErr = e;
        debugPrint('[CustomerApiService] $method $uri failed: $e');
      }
    }
    throw CustomerApiException('Server tidak dapat dijangkau ($lastErr)');
  }

  Future<({String token, CustomerUser user})> login(
    String identifier,
    String password,
  ) async {
    final data = await _requestJson(
      'POST',
      '/v1/auth/login',
      body: {'identifier': identifier, 'password': password},
    );
    final token = (data['token'] ?? '').toString();
    final user = CustomerUser.fromJson(
      data['user'] as Map<String, dynamic>? ?? {},
    );
    await _persistSession(token: token, user: user);
    return (token: token, user: user);
  }

  Future<({String token, CustomerUser user})> registerCustomer({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    final body = <String, dynamic>{
      'role': 'CUSTOMER',
      'name': name,
      'phone': phone,
      'password': password,
    };
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim().toLowerCase();
    }
    final data = await _requestJson('POST', '/v1/auth/register', body: body);
    final token = (data['token'] ?? '').toString();
    final user = CustomerUser.fromJson(
      data['user'] as Map<String, dynamic>? ?? {},
    );
    await _persistSession(token: token, user: user);
    return (token: token, user: user);
  }

  Future<({String token, CustomerUser user})> loginWithGoogle({
    required String email,
    String? googleUid,
    String? name,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'role': 'CUSTOMER',
    };
    if (googleUid != null && googleUid.isNotEmpty) {
      body['google_uid'] = googleUid;
    }
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      body['avatar_url'] = avatarUrl;
    }

    final data = await _requestJson('POST', '/v1/auth/google', body: body);
    final token = (data['token'] ?? '').toString();
    final user = CustomerUser.fromJson(
      data['user'] as Map<String, dynamic>? ?? {},
    );
    await _persistSession(token: token, user: user);
    return (token: token, user: user);
  }

  Future<CustomerUser> getMe() async {
    final data = await _requestJson('GET', '/v1/auth/me');
    final user = CustomerUser.fromJson(
      data['user'] as Map<String, dynamic>? ?? {},
    );
    await _persistSession(user: user);
    return user;
  }

  Future<CustomerUser> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
    if (phone != null && phone.trim().isNotEmpty) body['phone'] = phone.trim();
    if (email != null && email.trim().isNotEmpty) body['email'] = email.trim();
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      body['avatar_url'] = avatarUrl.trim();
    }
    final data = await _requestJson('PATCH', '/v1/auth/me', body: body);
    final user = CustomerUser.fromJson(
      data['user'] as Map<String, dynamic>? ?? {},
    );
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

  Future<String> uploadFile(
    String filePath, {
    String category = 'customer_avatar',
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
      } on CustomerApiException {
        rethrow;
      } catch (e) {
        lastErr = e;
      }
    }
    throw CustomerApiException('Gagal mengunggah berkas ($lastErr)');
  }

  Future<List<PublicStore>> getStores() async {
    final data = await _requestJson('GET', '/v1/stores');
    final raw = data['stores'] as List? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PublicStore.fromJson)
        .toList();
  }

  Future<PublicStore> getStoreDetail(String storeId) async {
    final data = await _requestJson('GET', '/v1/stores/$storeId');
    final map = data['store'] as Map<String, dynamic>? ?? data;
    return PublicStore.fromJson(map);
  }

  Future<List<PublicMenuItem>> getPublicMenus({
    String? query,
    String? category,
    String? storeId,
  }) async {
    final params = <String, String>{};
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();
    if (category != null && category.trim().isNotEmpty) {
      params['category'] = category.trim();
    }
    if (storeId != null && storeId.trim().isNotEmpty) {
      params['store_id'] = storeId.trim();
    }
    final q = Uri(queryParameters: params).query;
    final path = q.isNotEmpty ? '/v1/menus?$q' : '/v1/menus';
    final data = await _requestJson('GET', path);
    final raw = data['menus'] as List? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PublicMenuItem.fromJson)
        .toList();
  }

  Future<List<PromotionItem>> getPromotions() async {
    final data = await _requestJson('GET', '/v1/promotions');
    final raw = data['promotions'] as List? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PromotionItem.fromJson)
        .toList();
  }

  Future<List<UserFavorite>> getFavorites({String? userId}) async {
    final uid = userId ?? _userId;
    final path = (uid != null && uid.isNotEmpty)
        ? '/v1/favorites?user_id=$uid'
        : '/v1/favorites';
    final data = await _requestJson('GET', path);
    final raw = data['favorites'] as List? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(UserFavorite.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> addFavorite({
    required String targetType,
    String? storeId,
    String? menuId,
  }) {
    final body = <String, dynamic>{'target_type': targetType};
    if (_userId != null && _userId!.isNotEmpty) body['user_id'] = _userId;
    if (storeId != null && storeId.isNotEmpty) body['store_id'] = storeId;
    if (menuId != null && menuId.isNotEmpty) body['menu_id'] = menuId;
    return _requestJson('POST', '/v1/favorites', body: body);
  }

  Future<void> deleteFavorite(String favoriteId) async {
    await _requestJson('DELETE', '/v1/favorites/$favoriteId');
  }

  Future<OrderEstimate> estimateOrder({
    required String serviceType,
    String vehicleType = 'MOTOR',
    double pickupLat = 5.2041,
    double pickupLng = 97.0638,
    double dropoffLat = 5.2015,
    double dropoffLng = 97.0619,
    int itemsSubtotal = 0,
    int talanganEstAmount = 0,
    String? promoCode,
  }) async {
    final body = <String, dynamic>{
      'service_type': serviceType,
      'vehicle_type': vehicleType,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'items_subtotal': itemsSubtotal,
      'talangan_est_amount': talanganEstAmount,
    };
    if (promoCode != null && promoCode.isNotEmpty) {
      body['promo_code'] = promoCode;
    }
    final data = await _requestJson('POST', '/v1/orders/estimate', body: body);
    return OrderEstimate.fromJson(data);
  }

  Future<CustomerOrder> createOrder({
    required String serviceType,
    String vehicleType = 'MOTOR',
    String paymentMethod = 'CASH',
    String? storeId,
    required String pickupAddress,
    required String dropoffAddress,
    double pickupLat = 5.2041,
    double pickupLng = 97.0638,
    double dropoffLat = 5.2015,
    double dropoffLng = 97.0619,
    int itemsSubtotal = 0,
    int talanganEstAmount = 0,
    List<CustomerOrderItem> items = const [],
    String? promoCode,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'service_type': serviceType,
      'vehicle_type': vehicleType,
      'payment_method': paymentMethod,
      'pickup_address': pickupAddress,
      'dropoff_address': dropoffAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'items_subtotal': itemsSubtotal,
      'talangan_est_amount': talanganEstAmount,
      'items': items.map((e) => e.toJson()).toList(),
    };
    if (_userId != null && _userId!.isNotEmpty) body['customer_id'] = _userId;
    if (storeId != null && storeId.isNotEmpty) body['store_id'] = storeId;
    if (promoCode != null && promoCode.isNotEmpty) {
      body['promo_code'] = promoCode;
    }
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final data = await _requestJson('POST', '/v1/orders', body: body);
    final map = data['order'] as Map<String, dynamic>? ?? data;
    return CustomerOrder.fromJson(map);
  }

  Future<List<CustomerOrder>> getMyOrders() async {
    final uid = _userId ?? '';
    final path =
        uid.isNotEmpty ? '/v1/orders?customer_id=$uid' : '/v1/orders';
    final data = await _requestJson('GET', path);
    final raw = data['orders'] as List? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(CustomerOrder.fromJson)
        .toList();
  }

  Future<CustomerOrder> getOrder(String orderId) async {
    final data = await _requestJson('GET', '/v1/orders/$orderId');
    final map = data['order'] as Map<String, dynamic>? ?? data;
    return CustomerOrder.fromJson(map);
  }

  Future<void> submitRating(
    String orderId, {
    int? driverScore,
    int? storeScore,
    String comment = '',
  }) async {
    final body = <String, dynamic>{'comment': comment};
    if (_userId != null && _userId!.isNotEmpty) body['customer_id'] = _userId;
    if (driverScore != null) body['driver_score'] = driverScore;
    if (storeScore != null) body['store_score'] = storeScore;
    await _requestJson('POST', '/v1/orders/$orderId/rating', body: body);
  }

  Future<QrisPaymentResult> generateOrderQris({
    required String orderId,
    required int baseAmount,
  }) async {
    final body = <String, dynamic>{
      'purpose': 'ORDER_PAYMENT',
      'order_id': orderId,
      'base_amount': baseAmount,
      'amount': baseAmount,
    };
    if (_userId != null && _userId!.isNotEmpty) body['user_id'] = _userId;
    final data = await _requestJson('POST', '/pay/qris/generate', body: body);
    return QrisPaymentResult.fromJson(data);
  }

  Future<QrisPaymentResult> getQrisStatus(String referenceId) async {
    final data = await _requestJson('GET', '/pay/qris/$referenceId/status');
    return QrisPaymentResult.fromJson(data);
  }

  Future<String> aiChat({
    required String sessionId,
    required String message,
    String? systemPrompt,
  }) async {
    final body = <String, dynamic>{
      'session_id': sessionId,
      'app_role': 'CUSTOMER',
      'message': message,
    };
    if (_userId != null && _userId!.isNotEmpty) body['user_id'] = _userId;
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['system_prompt'] = systemPrompt;
    }
    final data = await _requestJson('POST', '/ai/chat', body: body);
    return (data['reply'] ?? data['message'] ?? data['content'] ?? '')
        .toString();
  }

  Future<Map<String, dynamic>> createSupportTicket({
    String? orderId,
    required String subject,
    required String bodyText,
  }) {
    final body = <String, dynamic>{
      'channel': 'IN_APP',
      'subject': subject,
      'body': bodyText,
    };
    if (_userId != null && _userId!.isNotEmpty) body['user_id'] = _userId;
    if (orderId != null && orderId.isNotEmpty) body['order_id'] = orderId;
    return _requestJson('POST', '/v1/support-tickets', body: body);
  }
}

