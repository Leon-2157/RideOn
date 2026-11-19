import 'dart:convert';
import 'dart:io';

import '../../../core/services/customer_api_service.dart';

class WaOtpSendResult {
  final bool success;
  final bool simulated;
  final String? simulatedCode;
  final String? message;
  final String? error;

  const WaOtpSendResult({
    required this.success,
    this.simulated = false,
    this.simulatedCode,
    this.message,
    this.error,
  });
}

/// Service komunikasi ke RideOn WhatsApp Gateway (`services/wa-gateway`)
/// Mendukung multi-endpoint fallback (USB ADB Reverse, Wi-Fi LAN IP, Android Emulator)
class WaGatewayService {
  final String? customBaseUrl;
  final HttpClient Function()? clientFactory;

  static const List<String> defaultCandidateUrls = [
    String.fromEnvironment('API_BASE_URL'),
    String.fromEnvironment('WA_GATEWAY_URL'),
    'http://10.0.2.2:8088',
    'http://127.0.0.1:8088',
    'http://localhost:8088',
    'https://api.rideons.app',
  ];

  String? _resolvedBaseUrl;

  WaGatewayService({
    this.customBaseUrl,
    this.clientFactory,
  });

  List<String> get _candidates {
    if (customBaseUrl != null) return [customBaseUrl!];
    final activeList = defaultCandidateUrls.where((u) => u.isNotEmpty).toList();
    if (_resolvedBaseUrl != null) {
      return [_resolvedBaseUrl!, ...activeList.where((u) => u != _resolvedBaseUrl)];
    }
    return activeList;
  }

  HttpClient _createClient() {
    final client = clientFactory != null ? clientFactory!() : HttpClient();
    client.connectionTimeout = const Duration(seconds: 3);
    return client;
  }

  /// Cek kesehatan server WA Gateway
  Future<bool> isGatewayOnline() async {
    for (final candidate in _candidates) {
      HttpClient? client;
      try {
        client = _createClient();
        final uri = Uri.parse('$candidate/health');
        final req = await client.getUrl(uri).timeout(const Duration(seconds: 3));
        final res = await req.close().timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          _resolvedBaseUrl = candidate;
          return true;
        }
      } catch (_) {
        continue;
      } finally {
        client?.close(force: true);
      }
    }
    return false;
  }

  /// Kirim kode OTP pendaftaran atau reset kata sandi via rideon-api / WA Gateway
  Future<WaOtpSendResult> sendOtp(String phoneNumber, {String purpose = 'REGISTER'}) async {
    if (customBaseUrl == null && clientFactory == null) {
      try {
        final res = await CustomerApiService().sendOtp(
          target: phoneNumber,
          channel: 'WHATSAPP',
          purpose: purpose.toUpperCase(),
        );
        return WaOtpSendResult(
          success: res['success'] != false,
          simulated: res['simulated'] == true,
          simulatedCode: (res['simulated_code'] ?? res['code'])?.toString(),
          message: (res['message'] ?? 'OTP terkirim via WhatsApp').toString(),
        );
      } catch (e) {
        return WaOtpSendResult(success: false, error: e.toString());
      }
    }

    String? lastError;

    for (final candidate in _candidates) {
      HttpClient? client;
      try {
        client = _createClient();
        final uri = Uri.parse('$candidate/api/otp/send');
        final req = await client.postUrl(uri).timeout(const Duration(seconds: 3));
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({
          'phoneNumber': phoneNumber,
          'purpose': purpose,
        }));
        final res = await req.close().timeout(const Duration(seconds: 4));

        final body = await res.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;

        if (res.statusCode == 200 && data['success'] == true) {
          _resolvedBaseUrl = candidate;
          return WaOtpSendResult(
            success: true,
            simulated: data['simulated'] == true,
            simulatedCode: data['code']?.toString(),
            message: data['message'] ?? 'OTP terkirim via WhatsApp',
          );
        } else {
          return WaOtpSendResult(
            success: false,
            error: data['error'] ?? 'Gagal mengirim OTP WhatsApp',
          );
        }
      } catch (e) {
        lastError = e.toString();
        continue;
      } finally {
        client?.close(force: true);
      }
    }

    return WaOtpSendResult(
      success: false,
      error: 'Layanan WhatsApp Gateway tidak dapat dihubungi ($lastError)',
    );
  }

  /// Verifikasi kode OTP 6 digit
  Future<bool> verifyOtp(String phoneNumber, String code) async {
    if (customBaseUrl == null && clientFactory == null) {
      try {
        return await CustomerApiService().verifyOtp(
          target: phoneNumber,
          channel: 'WHATSAPP',
          code: code,
        );
      } catch (_) {
        return false;
      }
    }

    for (final candidate in _candidates) {
      HttpClient? client;
      try {
        client = _createClient();
        final uri = Uri.parse('$candidate/api/otp/verify');
        final req = await client.postUrl(uri).timeout(const Duration(seconds: 3));
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({'phoneNumber': phoneNumber, 'code': code}));
        final res = await req.close().timeout(const Duration(seconds: 4));

        final body = await res.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;

        if (res.statusCode == 200 && data['success'] == true) {
          _resolvedBaseUrl = candidate;
          return true;
        }
      } catch (_) {
        continue;
      } finally {
        client?.close(force: true);
      }
    }
    return false;
  }

  /// Reset kata sandi pengguna via WhatsApp Gateway (Firebase Admin SDK)
  Future<Map<String, dynamic>> resetPassword({
    required String phoneNumber,
    required String newPassword,
  }) async {
    String? lastError;
    for (final candidate in _candidates) {
      HttpClient? client;
      try {
        client = _createClient();
        final uri = Uri.parse('$candidate/api/auth/reset-password');
        final req = await client.postUrl(uri).timeout(const Duration(seconds: 4));
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({
          'phoneNumber': phoneNumber,
          'newPassword': newPassword,
        }));
        final res = await req.close().timeout(const Duration(seconds: 5));
        final body = await res.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;

        if (res.statusCode == 200 && data['success'] == true) {
          _resolvedBaseUrl = candidate;
          return {
            'success': true,
            'message': data['message'] ?? 'Kata sandi berhasil diperbarui',
          };
        } else {
          return {
            'success': false,
            'error': data['error'] ?? 'Gagal memperbarui kata sandi',
          };
        }
      } catch (e) {
        lastError = e.toString();
        continue;
      } finally {
        client?.close(force: true);
      }
    }

    return {
      'success': false,
      'error': 'Layanan WhatsApp Gateway tidak dapat dihubungi ($lastError)',
    };
  }
}
