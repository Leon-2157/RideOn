import 'dart:convert';
import 'dart:io';

class EmailOtpSendResult {
  final bool success;
  final String? message;
  final String? error;
  final String? devOtp;

  const EmailOtpSendResult({
    required this.success,
    this.message,
    this.error,
    this.devOtp,
  });
}

class EmailOtpVerifyResult {
  final bool success;
  final String? message;
  final String? error;

  const EmailOtpVerifyResult({
    required this.success,
    this.message,
    this.error,
  });
}

/// Service komunikasi pengiriman & verifikasi kode OTP Email via RideOn Gateway
class EmailOtpService {
  final String? customBaseUrl;
  final HttpClient Function()? clientFactory;

  static const List<String> defaultCandidateUrls = [
    String.fromEnvironment('WA_GATEWAY_URL'),
    'http://10.45.209.43:3000',      // Active Wi-Fi LAN IP
    'http://localhost:3000',         // ADB Reverse port forwarding
    'http://127.0.0.1:3000',
    'http://192.168.100.14:3000',    // Secondary Wi-Fi LAN IP
    'http://192.168.100.225:3000',
    'http://10.0.2.2:3000',          // Android Emulator
  ];

  String? _resolvedBaseUrl;

  EmailOtpService({
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
    client.connectionTimeout = const Duration(seconds: 4);
    return client;
  }

  /// Kirim kode verifikasi OTP ke alamat email
  Future<EmailOtpSendResult> sendOtp(String email, {String purpose = 'verifikasi_email'}) async {
    String? lastError;

    for (final candidate in _candidates) {
      HttpClient? client;
      try {
        client = _createClient();
        final uri = Uri.parse('$candidate/api/email/otp/send');
        final req = await client.postUrl(uri).timeout(const Duration(seconds: 4));
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({
          'email': email.trim().toLowerCase(),
          'purpose': purpose,
        }));
        final res = await req.close().timeout(const Duration(seconds: 5));

        final body = await res.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;

        if (res.statusCode == 200 && data['success'] == true) {
          _resolvedBaseUrl = candidate;
          return EmailOtpSendResult(
            success: true,
            message: data['message'] ?? 'Kode verifikasi telah dikirimkan ke email Anda.',
            devOtp: data['devOtp']?.toString(),
          );
        } else {
          return EmailOtpSendResult(
            success: false,
            error: data['error'] ?? 'Gagal mengirim kode verifikasi email.',
          );
        }
      } catch (e) {
        lastError = e.toString();
        continue;
      } finally {
        client?.close(force: true);
      }
    }

    return EmailOtpSendResult(
      success: false,
      error: 'Layanan email verification tidak dapat dihubungi ($lastError)',
    );
  }

  /// Verifikasi kode OTP 6 digit email
  Future<EmailOtpVerifyResult> verifyOtp(String email, String code) async {
    String? lastError;

    for (final candidate in _candidates) {
      HttpClient? client;
      try {
        client = _createClient();
        final uri = Uri.parse('$candidate/api/email/otp/verify');
        final req = await client.postUrl(uri).timeout(const Duration(seconds: 4));
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
        }));
        final res = await req.close().timeout(const Duration(seconds: 5));

        final body = await res.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;

        if (res.statusCode == 200 && data['success'] == true) {
          _resolvedBaseUrl = candidate;
          return EmailOtpVerifyResult(
            success: true,
            message: data['message'] ?? 'Alamat email berhasil diverifikasi.',
          );
        } else {
          return EmailOtpVerifyResult(
            success: false,
            error: data['error'] ?? 'Kode verifikasi yang Anda masukkan salah.',
          );
        }
      } catch (e) {
        lastError = e.toString();
        continue;
      } finally {
        client?.close(force: true);
      }
    }

    return EmailOtpVerifyResult(
      success: false,
      error: 'Layanan verifikasi tidak dapat dihubungi ($lastError)',
    );
  }
}

