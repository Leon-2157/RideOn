import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideon/features/auth/data/email_otp_service.dart';
import 'package:rideon/features/pengaturan/presentation/widgets/email_success_dialog.dart';

void main() {
  group('EmailOtpService Tests', () {
    test('sendOtp returns success when server responds 200 with success true', () async {
      final mockClient = _MockHttpClient((request) async {
        if (request.uri.path == '/api/email/otp/send') {
          return _MockHttpClientResponse(
            statusCode: 200,
            body: jsonEncode({
              'success': true,
              'message': 'Kode OTP terkirim ke email',
              'devOtp': '123456',
            }),
          );
        }
        return _MockHttpClientResponse(statusCode: 404, body: '{}');
      });

      final service = EmailOtpService(
        customBaseUrl: 'http://test-server:3000',
        clientFactory: () => mockClient,
      );

      final result = await service.sendOtp('test@rideon.id');
      expect(result.success, isTrue);
      expect(result.message, equals('Kode OTP terkirim ke email'));
      expect(result.devOtp, equals('123456'));
    });

    test('sendOtp returns failure when server returns error', () async {
      final mockClient = _MockHttpClient((request) async {
        return _MockHttpClientResponse(
          statusCode: 400,
          body: jsonEncode({
            'success': false,
            'error': 'Format email tidak valid',
          }),
        );
      });

      final service = EmailOtpService(
        customBaseUrl: 'http://test-server:3000',
        clientFactory: () => mockClient,
      );

      final result = await service.sendOtp('bad-email');
      expect(result.success, isFalse);
      expect(result.error, equals('Format email tidak valid'));
    });

    test('verifyOtp returns true when code is valid', () async {
      final mockClient = _MockHttpClient((request) async {
        if (request.uri.path == '/api/email/otp/verify') {
          return _MockHttpClientResponse(
            statusCode: 200,
            body: jsonEncode({
              'success': true,
              'message': 'Alamat email berhasil diverifikasi',
            }),
          );
        }
        return _MockHttpClientResponse(statusCode: 404, body: '{}');
      });

      final service = EmailOtpService(
        customBaseUrl: 'http://test-server:3000',
        clientFactory: () => mockClient,
      );

      final result = await service.verifyOtp('test@rideon.id', '123456');
      expect(result.success, isTrue);
      expect(result.message, equals('Alamat email berhasil diverifikasi'));
    });

    test('verifyOtp returns false when code is invalid', () async {
      final mockClient = _MockHttpClient((request) async {
        return _MockHttpClientResponse(
          statusCode: 400,
          body: jsonEncode({
            'success': false,
            'error': 'Kode verifikasi yang Anda masukkan salah.',
          }),
        );
      });

      final service = EmailOtpService(
        customBaseUrl: 'http://test-server:3000',
        clientFactory: () => mockClient,
      );

      final result = await service.verifyOtp('test@rideon.id', '999999');
      expect(result.success, isFalse);
      expect(result.error, equals('Kode verifikasi yang Anda masukkan salah.'));
    });
  });

  group('EmailSuccessDialog Tests', () {
    testWidgets('renders all elements matching Figma email success ditambahkan.jpg', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool finishedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  EmailSuccessDialog.show(
                    context,
                    email: 'test@gmail.com',
                    isUpdate: false,
                    onFinished: () {
                      finishedCalled = true;
                    },
                  );
                },
                child: const Text('SHOW'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('SHOW'));
      await tester.pumpAndSettle();

      expect(find.text('Email Berhasil Ditambahkan!'), findsOneWidget);
      expect(find.textContaining('Alamat email baru Anda telah berhasil diverifikasi'), findsOneWidget);
      expect(find.text('SELESAI'), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.text('SELESAI'));
      await tester.pumpAndSettle();

      expect(find.text('Email Berhasil Ditambahkan!'), findsNothing);
      expect(finishedCalled, isTrue);
    });

    testWidgets('renders update title when isUpdate is true', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  EmailSuccessDialog.show(
                    context,
                    email: 'test@gmail.com',
                    isUpdate: true,
                  );
                },
                child: const Text('SHOW'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('SHOW'));
      await tester.pumpAndSettle();

      expect(find.text('Email Berhasil Diperbarui!'), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Mock HttpClient utilities for testing
// ---------------------------------------------------------------------------

typedef _RequestHandler = Future<_MockHttpClientResponse> Function(_MockHttpClientRequest);

class _MockHttpClient implements HttpClient {
  final _RequestHandler handler;
  _MockHttpClient(this.handler);

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _MockHttpClientRequest(url, handler);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest(url, handler);
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final Uri uri;
  final _RequestHandler handler;
  final List<int> _bodyBytes = [];

  _MockHttpClientRequest(this.uri, this.handler);

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  void write(Object? obj) {
    if (obj != null) {
      _bodyBytes.addAll(utf8.encode(obj.toString()));
    }
  }

  @override
  Future<HttpClientResponse> close() async {
    return handler(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  ContentType? contentType;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final int statusCode;
  final String body;

  _MockHttpClientResponse({required this.statusCode, required this.body});

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(utf8.encode(body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
