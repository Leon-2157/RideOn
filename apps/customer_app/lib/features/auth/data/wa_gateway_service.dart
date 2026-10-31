import 'dart:convert';
import 'dart:io';

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
    String.fromEnvironment('WA_GATEWAY_URL'),
    'http://192.168.100.14:3000',
    'http://localhost:3000',
    'http://192.168.100.225:3000',
    'http://10.0.2.2:3000',
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

  /// Kirim kode OTP pendaftaran atau reset kata sandi via WhatsApp Gateway
  Future<WaOtpSendResult> sendOtp(String phoneNumber, {String purpose = 'register'}) async {
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
