import 'dart:convert';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../utils/debug_helper.dart';

/// Dio for unauthenticated calls (login, signup) — no bearer token interceptor.
class PublicDioClient {
  PublicDioClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 600,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          DebugHelper.logApiCall(
            options.method,
            options.uri.toString(),
            options.headers.map((k, v) => MapEntry(k, v.toString())),
            options.data,
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          final body = response.data;
          final text = body is String
              ? body
              : body == null
                  ? ''
                  : jsonEncode(body);
          DebugHelper.logApiResponse(
            response.statusCode ?? 0,
            text,
            response.requestOptions.uri.toString(),
          );
          handler.next(response);
        },
        onError: (error, handler) {
          DebugHelper.logError(
            'PublicDio ${error.requestOptions.uri}',
            error,
            error.stackTrace,
          );
          handler.next(error);
        },
      ),
    );
  }

  static final PublicDioClient instance = PublicDioClient._();

  late final Dio _dio;
  Dio get dio => _dio;

  String messageFromError(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Check that the backend is running at '
            '${ApiConstants.baseUrl} and your phone is on the same Wi‑Fi. '
            'Android emulator: use http://10.0.2.2:9080/api/v1 in api_constants.dart.';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond. Try again or check backend load.';
      case DioExceptionType.sendTimeout:
        return 'Upload timed out. Check your network connection.';
      case DioExceptionType.connectionError:
        return 'Cannot reach server at ${ApiConstants.baseUrl}. '
            'Verify IP address, port 9080, firewall, and that Spring Boot is running.';
      default:
        return error.message ?? 'Network request failed';
    }
  }
}
