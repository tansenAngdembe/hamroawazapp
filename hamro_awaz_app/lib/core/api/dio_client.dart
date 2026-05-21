import 'dart:convert';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../utils/debug_helper.dart';
import '../../services/auth_service.dart';

/// Dio HTTP client with auth header injection and debug logging.
class DioClient {
  DioClient({required AuthService authService})
      : _auth = authService,
        dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: ApiConstants.connectTimeout,
            receiveTimeout: ApiConstants.receiveTimeout,
            sendTimeout: const Duration(seconds: 60),
            headers: {
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _auth.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
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
            'Dio error ${error.requestOptions.uri}',
            error,
            error.stackTrace,
          );
          handler.next(error);
        },
      ),
    );
  }

  final AuthService _auth;
  final Dio dio;

  String messageFromError(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final msg = data['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. Check your network and server.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Cannot reach server at ${ApiConstants.baseUrl}';
    }
    return error.message ?? 'Network request failed';
  }
}
