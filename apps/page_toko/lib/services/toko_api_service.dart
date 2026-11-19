import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_model.dart';
import '../models/store_model.dart';
import '../models/store_order_model.dart';
import '../models/store_wallet_model.dart';

class TokoApiException implements Exception {
  final int statusCode;
  final String message;

  TokoApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class TokoApiService {
  static final TokoApiService _instance = TokoApiService._internal();
  factory TokoApiService() => _instance;
  TokoApiService._internal();

  /// Set true only inside legacy UI widget test setUp() blocks.
  static bool enableLocalFallback = false;

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static final List<String> _fallbackBaseUrls = <String>[
    if (_envBaseUrl.isNotEmpty) _envBaseUrl,
    'http://10.0.2.2:8088',
    'http://localhost:8088',
    'https://api.rideons.app',
  ];

  static const _kToken = 'toko_jwt_token';
  static const _kUserId = 'toko_user_id';
  static const _kStoreId = 'toko_store_id';
  static const _kUserStatus = 'toko_user_status';
  static const _kStoreName = 'toko_store_name';
  static const _kOwnerName = 'toko_owner_name';
  static const _kEmail = 'toko_email';
  static const _kPhone = 'toko_phone';

  http.Client? clientOverride;
  String? _token;
  String? _userId;
  String? _storeId;
  String _userStatus = 'ACTIVE';
  String _activeBaseUrl = _fallbackBaseUrls.first;

  bool get hasSession => _token != null && _token!.isNotEmpty;
  String? get savedUserId => _userId;
  String? get savedStoreId => _storeId;
  String get savedUserStatus => _userStatus;

  http.Client get _client => clientOverride ?? http.Client();

  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _userId = prefs.getString(_kUserId);
    _storeId = prefs.getString(_kStoreId);
    _userStatus = prefs.getString(_kUserStatus) ?? 'ACTIVE';
    return hasSession;
  }

  Future<void> saveSession(String token, StoreUser user) async {
    _token = token;
    _userId = user.id;
    _storeId = user.store?.id ?? '';
    _userStatus = user.status;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUserId, user.id);
    if (_storeId != null && _storeId!.isNotEmpty) {
      await prefs.setString(_kStoreId, _storeId!);
    }
    await prefs.setString(_kUserStatus, user.status);
    if (user.store != null) {
      await prefs.setString(_kStoreName, user.store!.storeName);
    }
    await prefs.setString(_kOwnerName, user.name);
    await prefs.setString(_kEmail, user.email);
    await prefs.setString(_kPhone, user.phone);
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _storeId = null;
    _userStatus = 'ACTIVE';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kStoreId);
    await prefs.remove(_kUserStatus);
    await prefs.remove(_kStoreName);
    await prefs.remove(_kOwnerName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kPhone);
  }

  Future<http.Response> _requestWithFallback(
    Future<http.Response> Function(String baseUrl, Map<String, String> headers) fn,
  ) async {
    final candidates = clientOverride != null
        ? <String>[_activeBaseUrl]
        : <String>[_activeBaseUrl, ..._fallbackBaseUrls.where((u) => u != _activeBaseUrl)];

    Object? lastErr;
    for (final base in candidates) {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (_token != null && _token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_token';
      }
      try {
        final res = await fn(base, headers).timeout(const Duration(seconds: 8));
        _activeBaseUrl = base;
        return res;
      } on SocketException catch (e) {
        lastErr = e;
      } on http.ClientException catch (e) {
        lastErr = e;
      } on Exception catch (e) {
        lastErr = e;
      }
    }
    throw TokoApiException(503, 'Tidak dapat terhubung ke server RideOn: $lastErr');
  }

  Map<String, dynamic> _decodeOrThrow(http.Response res) {
    Map<String, dynamic> data = {};
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {}
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = (data['error'] ?? 'Permintaan gagal (HTTP ${res.statusCode})').toString();
      throw TokoApiException(res.statusCode, msg);
    }
    return data;
  }

  Future<StoreUser> login(String identifier, String password) async {
    final res = await _requestWithFallback(
      (base, headers) => _client.post(
        Uri.parse('$base/v1/auth/login'),
        headers: headers,
        body: jsonEncode({'identifier': identifier, 'password': password}),
      ),
    );
    final data = _decodeOrThrow(res);
    final token = (data['token'] ?? '').toString();
    final userMap = data['user'] as Map<String, dynamic>? ?? {};
    final user = StoreUser.fromJson(userMap);
    if (user.role != 'STORE' && user.role != 'ADMIN') {
      throw TokoApiException(403, 'Akun ini bukan akun Mitra Toko (${user.role}).');
    }
    if (user.status == 'REJECTED' || user.status == 'SUSPENDED') {
      throw TokoApiException(403, 'Akun toko Anda berstatus ${user.status}. Hubungi Admin RideOn.');
    }
    await saveSession(token, user);
    return user;
  }

  Future<StoreUser> getMe() async {
    final res = await _requestWithFallback(
      (base, headers) => _client.get(Uri.parse('$base/v1/auth/me'), headers: headers),
    );
    final data = _decodeOrThrow(res);
    final user = StoreUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
    if (_token != null) {
      await saveSession(_token!, user);
    }
    return user;
  }

  Future<Map<String, dynamic>> sendOtp(
    String target, {
    String channel = 'WHATSAPP',
    String purpose = 'REGISTER',
  }) async {
    final res = await _requestWithFallback(
      (base, headers) => _client.post(
        Uri.parse('$base/v1/auth/otp/send'),
        headers: headers,
        body: jsonEncode({'target': target, 'channel': channel, 'purpose': purpose}),
      ),
    );
    return _decodeOrThrow(res);
  }

  Future<bool> verifyOtp(String target, String code, {String? channel}) async {
    final body = <String, dynamic>{'target': target, 'code': code};
    if (channel != null && channel.isNotEmpty) {
      body['channel'] = channel;
    }
    final res = await _requestWithFallback(
      (base, headers) => _client.post(
        Uri.parse('$base/v1/auth/otp/verify'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    final data = _decodeOrThrow(res);
    return data['verified'] == true || data['success'] == true;
  }

  Future<String> uploadFile(String filePath, {String category = 'store'}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return '/uploads/$category/placeholder.jpg';
    }
    final bytes = await file.readAsBytes();
    final name = filePath.split('/').last;
    return uploadBytes(bytes, name, category: category);
  }

  Future<String> uploadBytes(List<int> bytes, String filename, {String category = 'store'}) async {
    final uri = Uri.parse('$_activeBaseUrl/v1/upload');
    final request = http.MultipartRequest('POST', uri);
    request.fields['category'] = category;
    if (_token != null && _token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await _client.send(request).timeout(const Duration(seconds: 12));
    final res = await http.Response.fromStream(streamed);
    final data = _decodeOrThrow(res);
    return (data['url'] ?? '').toString();
  }

  Future<Map<String, double>> geocodeAddress(String address) async {
    try {
      final q = Uri.encodeQueryComponent('$address, Lhokseumawe, Aceh, Indonesia');
      final res = await _client
          .get(
            Uri.parse('https://nominatim.openstreetmap.org/search?format=json&limit=1&q=$q'),
            headers: {'User-Agent': 'RideOn-Toko-App/1.0'},
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first as Map<String, dynamic>;
          final lat = double.tryParse((first['lat'] ?? '').toString());
          final lon = double.tryParse((first['lon'] ?? '').toString());
          if (lat != null && lon != null) {
            return {'lat': lat, 'lng': lon};
          }
        }
      }
    } catch (_) {}
    return {'lat': 5.1801, 'lng': 97.1507};
  }

  Future<StoreUser> registerStore({
    required String ownerName,
    required String email,
    required String phone,
    required String password,
    required String storeName,
    required String category,
    required String description,
    required String address,
    required double lat,
    required double lng,
    String openTime = '08:00',
    String closeTime = '22:00',
    String storePin = '123456',
    String businessDocUrl = '',
  }) async {
    final body = <String, dynamic>{
      'role': 'STORE',
      'name': ownerName,
      'email': email,
      'phone': phone,
      'password': password,
      'store_name': storeName,
      'category': category,
      'description': description,
      'address': address,
      'lat': lat,
      'lng': lng,
      'open_time': openTime,
      'close_time': closeTime,
      'store_pin': storePin,
    };
    if (businessDocUrl.isNotEmpty) {
      body['business_doc_url'] = businessDocUrl;
    }
    final res = await _requestWithFallback(
      (base, headers) => _client.post(
        Uri.parse('$base/v1/auth/register'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    final data = _decodeOrThrow(res);
    final token = (data['token'] ?? '').toString();
    final user = StoreUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
    if (token.isNotEmpty) {
      await saveSession(token, user);
    }
    return user;
  }

  Future<StoreProfile> getStoreDetail(String storeId) async {
    final res = await _requestWithFallback(
      (base, headers) => _client.get(Uri.parse('$base/v1/stores/$storeId'), headers: headers),
    );
    final data = _decodeOrThrow(res);
    return StoreProfile.fromJson(data['store'] as Map<String, dynamic>? ?? data);
  }

  Future<bool> setStoreOpenStatus(String storeId, bool isOpen) async {
    final res = await _requestWithFallback(
      (base, headers) => _client.patch(
        Uri.parse('$base/v1/stores/$storeId/status'),
        headers: headers,
        body: jsonEncode({'is_open': isOpen}),
      ),
    );
    final data = _decodeOrThrow(res);
    return data['is_open'] == true;
  }

  Future<List<StoreMenuModel>> getMenus(String storeId) async {
    final res = await _requestWithFallback(
      (base, headers) => _client.get(Uri.parse('$base/v1/stores/$storeId/menus'), headers: headers),
    );
    final data = _decodeOrThrow(res);
    final list = (data['menus'] as List<dynamic>?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map(StoreMenuModel.fromJson).toList();
  }

  Future<StoreMenuModel> createMenu(
    String storeId, {
    required String name,
    required String category,
    required int price,
    String description = '',
    String? photoUrl,
    bool isAvailable = true,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'is_available': isAvailable,
    };
    if (photoUrl != null && photoUrl.isNotEmpty) {
      body['photo_url'] = photoUrl;
    }
    final res = await _requestWithFallback(
      (base, headers) => _client.post(
        Uri.parse('$base/v1/stores/$storeId/menus'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    return StoreMenuModel.fromJson(_decodeOrThrow(res));
  }

  Future<StoreMenuModel> updateMenu(
    String storeId,
    String menuId, {
    String? name,
    String? category,
    int? price,
    String? description,
    String? photoUrl,
    bool? isAvailable,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (category != null) body['category'] = category;
    if (price != null) body['price'] = price;
    if (description != null) body['description'] = description;
    if (photoUrl != null) body['photo_url'] = photoUrl;
    if (isAvailable != null) body['is_available'] = isAvailable;

    final res = await _requestWithFallback(
      (base, headers) => _client.put(
        Uri.parse('$base/v1/stores/$storeId/menus/$menuId'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    return StoreMenuModel.fromJson(_decodeOrThrow(res));
  }

  Future<void> deleteMenu(String storeId, String menuId) async {
    final res = await _requestWithFallback(
      (base, headers) => _client.delete(
        Uri.parse('$base/v1/stores/$storeId/menus/$menuId'),
        headers: headers,
      ),
    );
    _decodeOrThrow(res);
  }

  Future<List<StoreOrderModel>> getStoreOrders(String storeId, {String? status}) async {
    var path = '/v1/orders?store_id=$storeId';
    if (status != null && status.isNotEmpty) {
      path += '&status=$status';
    }
    final res = await _requestWithFallback(
      (base, headers) => _client.get(Uri.parse('$base$path'), headers: headers),
    );
    final data = _decodeOrThrow(res);
    final list = (data['orders'] as List<dynamic>?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map(StoreOrderModel.fromJson).toList();
  }

  Future<void> confirmOrder(String orderId) async {
    final res = await _requestWithFallback(
      (base, headers) => _client.post(
        Uri.parse('$base/v1/orders/$orderId/store-confirm'),
        headers: headers,
        body: jsonEncode({}),
      ),
    );
    _decodeOrThrow(res);
  }

  Future<void> rejectOrder(String orderId, {String reason = 'Stok menu sedang habis'}) async {
    final res = await _requestWithFallback(
      (base, headers) => _client.post(
        Uri.parse('$base/v1/orders/$orderId/store-reject'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      ),
    );
    _decodeOrThrow(res);
  }

  Future<StoreWalletModel> getStoreWallet(String storeId) async {
    final res = await _requestWithFallback(
      (base, headers) => _client.get(Uri.parse('$base/v1/wallets/STORE/$storeId'), headers: headers),
    );
    return StoreWalletModel.fromJson(_decodeOrThrow(res));
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required String storeId,
    required int amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
    required String pin,
  }) async {
    final res = await _requestWithFallback(
      (base, headers) => _client.post(
        Uri.parse('$base/v1/withdrawals'),
        headers: headers,
        body: jsonEncode({
          'owner_type': 'STORE',
          'owner_id': storeId,
          'requester_user_id': _userId ?? '',
          'amount': amount,
          'bank_name': bankName,
          'bank_account_number': accountNumber,
          'bank_account_holder': accountName,
          'pin': pin,
        }),
      ),
    );
    return _decodeOrThrow(res);
  }

  Future<String> aiChat({
    required String sessionId,
    required String message,
    String? systemPrompt,
  }) async {
    final body = <String, dynamic>{
      'session_id': sessionId,
      'user_id': _userId ?? '',
      'app_role': 'STORE',
      'message': message,
    };
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['system_prompt'] = systemPrompt;
    }
    final res = await _requestWithFallback(
      (base, headers) => _client.post(
        Uri.parse('$base/ai/chat'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    final data = _decodeOrThrow(res);
    return (data['reply'] ?? '').toString();
  }

  Future<Map<String, dynamic>> createSupportTicket({
    required String subject,
    required String message,
    String? orderId,
  }) async {
    final body = <String, dynamic>{
      'channel': 'IN_APP',
      'subject': subject,
      'body': message,
    };
    if (_userId != null && _userId!.isNotEmpty) {
      body['user_id'] = _userId;
    }
    if (orderId != null && orderId.isNotEmpty) {
      body['order_id'] = orderId;
    }
    final res = await _requestWithFallback(
      (base, headers) => _client.post(
        Uri.parse('$base/v1/support-tickets'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    return _decodeOrThrow(res);
  }
}

