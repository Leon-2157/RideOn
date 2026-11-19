import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Model hasil pencarian lokasi dari OpenStreetMap Nominatim API.
class OsmPlaceResult {
  final String placeId;
  final String title;
  final String subtitle;
  final String displayName;
  final double lat;
  final double lng;
  final String? category;
  final double? distanceKm;

  const OsmPlaceResult({
    required this.placeId,
    required this.title,
    required this.subtitle,
    required this.displayName,
    required this.lat,
    required this.lng,
    this.category,
    this.distanceKm,
  });

  /// String alamat ringkas yang nyaman dimasukkan ke form jemput / tujuan.
  String get formattedAddress {
    if (subtitle.isEmpty || title.toLowerCase() == subtitle.toLowerCase()) {
      return title;
    }
    return '$title, $subtitle';
  }

  String? get formattedDistance {
    if (distanceKm == null) return null;
    if (distanceKm! < 1.0) {
      return '${(distanceKm! * 1000).round()} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }
}

/// Service bersama untuk pencarian alamat & tempat via OpenStreetMap Nominatim
/// serta pembacaan alamat tersimpan pengguna dari Firestore.
///
/// Mengikuti kebijakan penggunaan Nominatim:
/// - Mengirim header `User-Agent` aplikasi yang valid
/// - Timeout ketat agar UI tetap responsif saat jaringan lambat
/// - Cache in-memory untuk menghindari request berulang pada query yang sama
class OsmNominatimService {
  static final OsmNominatimService instance = OsmNominatimService();

  static const String _userAgent =
      'RideOnCustomerApp/1.0 (https://github.com/Leon-2157/RideOn)';
  static const int _maxCacheEntries = 60;

  // Fallback referensi koordinat area operasional awal (Lhokseumawe / Dewantara)
  static const double defaultLat = 5.2472;
  static const double defaultLng = 97.0261;

  final Future<String> Function(Uri uri)? httpGetOverride;
  final Map<String, List<OsmPlaceResult>> _cache = {};

  OsmNominatimService({
    this.httpGetOverride,
  });

  /// Mencari tempat/jalan di Indonesia via OpenStreetMap Nominatim API.
  Future<List<OsmPlaceResult>> searchPlaces(
    String query, {
    double? nearLat,
    double? nearLng,
    int limit = 8,
  }) async {
    final normalized = query.trim();
    if (normalized.length < 2) {
      return const [];
    }

    final refLat = nearLat ?? defaultLat;
    final refLng = nearLng ?? defaultLng;
    final cacheKey =
        '${normalized.toLowerCase()}|${refLat.toStringAsFixed(2)}|${refLng.toStringAsFixed(2)}|$limit';

    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final viewbox =
        '${(refLng - 0.35).toStringAsFixed(4)},${(refLat + 0.35).toStringAsFixed(4)},'
        '${(refLng + 0.35).toStringAsFixed(4)},${(refLat - 0.35).toStringAsFixed(4)}';

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': normalized,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': limit.toString(),
      'countrycodes': 'id',
      'accept-language': 'id',
      'viewbox': viewbox,
    });

    try {
      final rawBody = await _performGet(uri);
      final decoded = jsonDecode(rawBody);
      if (decoded is! List) return const [];

      final results = <OsmPlaceResult>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final lat = double.tryParse(item['lat']?.toString() ?? '');
        final lng = double.tryParse(item['lon']?.toString() ?? '');
        final displayName = (item['display_name'] as String? ?? '').trim();
        if (lat == null || lng == null || displayName.isEmpty) continue;

        final parsed = _parseTitleAndSubtitle(item, displayName);
        final distMeters = Geolocator.distanceBetween(refLat, refLng, lat, lng);

        results.add(
          OsmPlaceResult(
            placeId: item['place_id']?.toString() ?? displayName,
            title: parsed.$1,
            subtitle: parsed.$2,
            displayName: displayName,
            lat: lat,
            lng: lng,
            category: item['type'] as String? ?? item['category'] as String?,
            distanceKm: distMeters / 1000.0,
          ),
        );
      }

      if (_cache.length >= _maxCacheEntries) {
        _cache.remove(_cache.keys.first);
      }
      _cache[cacheKey] = results;
      return results;
    } catch (_) {
      return const [];
    }
  }

  Future<String> _performGet(Uri uri) async {
    if (httpGetOverride != null) {
      return httpGetOverride!(uri);
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6);
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 6));
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response =
          await request.close().timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        throw HttpException('Nominatim HTTP ${response.statusCode}', uri: uri);
      }
      return await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 6));
    } finally {
      client.close(force: true);
    }
  }

  (String, String) _parseTitleAndSubtitle(
    Map<String, dynamic> item,
    String displayName,
  ) {
    final explicitName = (item['name'] as String? ?? '').trim();
    final parts = displayName
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final address = item['address'];
    String title = explicitName;
    if (title.isEmpty && address is Map<String, dynamic>) {
      title = (address['road'] ??
              address['amenity'] ??
              address['shop'] ??
              address['tourism'] ??
              address['village'] ??
              address['suburb'] ??
              '')
          .toString()
          .trim();
    }
    if (title.isEmpty) {
      title = parts.isNotEmpty ? parts.first : displayName;
    }

    final subtitleParts = <String>[];
    if (address is Map<String, dynamic>) {
      for (final key in [
        'road',
        'village',
        'suburb',
        'city_district',
        'city',
        'town',
        'county',
        'state',
      ]) {
        final val = (address[key] as String? ?? '').trim();
        if (val.isNotEmpty &&
            val.toLowerCase() != title.toLowerCase() &&
            !subtitleParts.contains(val)) {
          subtitleParts.add(val);
        }
        if (subtitleParts.length >= 3) break;
      }
    }

    if (subtitleParts.isEmpty && parts.length > 1) {
      subtitleParts.addAll(
        parts
            .where((p) => p.toLowerCase() != title.toLowerCase())
            .take(3),
      );
    }

    return (title, subtitleParts.join(', '));
  }

  /// Mengambil koordinat terakhir/saat ini hanya jika izin lokasi sudah diberikan
  /// (tidak memicu dialog izin lokasi secara mendadak saat user membuka search).
  static Future<LatLng?> tryGetKnownUserPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LatLng(lastKnown.latitude, lastKnown.longitude);
      }

      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );
      return LatLng(current.latitude, current.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Memuat alamat tersimpan pengguna dari Firestore (`users/{uid}`) secara aman.
  static Future<List<Map<String, dynamic>>> loadSavedAddresses({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) async {
    final results = <Map<String, dynamic>>[];
    try {
      final resolvedAuth = auth ?? FirebaseAuth.instance;
      final resolvedFirestore = firestore ?? FirebaseFirestore.instance;
      final user = resolvedAuth.currentUser;
      if (user == null) return results;

      final subSnap = await resolvedFirestore
          .collection('users')
          .doc(user.uid)
          .collection('savedAddresses')
          .get();
      for (final doc in subSnap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        results.add(data);
      }

      final userDoc =
          await resolvedFirestore.collection('users').doc(user.uid).get();
      final savedSingle =
          userDoc.data()?['savedAddress'] as Map<String, dynamic>?;
      if (savedSingle != null &&
          (savedSingle['address'] as String? ?? '').isNotEmpty) {
        final addrText = (savedSingle['address'] as String).toLowerCase();
        final alreadyIncluded = results.any(
          (r) => (r['address'] as String? ?? '').toLowerCase() == addrText,
        );
        if (!alreadyIncluded) {
          results.insert(0, Map<String, dynamic>.from(savedSingle));
        }
      }
    } catch (_) {
      // Aman saat Firebase belum diinisialisasi di environment test atau offline
    }
    return results;
  }
}
