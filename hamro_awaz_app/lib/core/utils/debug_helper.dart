import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DebugHelper {
  /// Always log API traffic in debug/profile; never in release.
  static bool get isDebugMode => !kReleaseMode;

  static void log(String message, [Object? data]) {
    if (!isDebugMode) return;
    debugPrint('[DEBUG] $message');
    if (data != null) {
      debugPrint('[DEBUG] Data: ${describeBody(data)}');
    }
  }

  static void logError(String message, [Object? error, StackTrace? stackTrace]) {
    if (!isDebugMode) return;
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('[ERROR] Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('[ERROR] Stack trace: $stackTrace');
    }
  }

  /// Safe string for logs — never throws on FormData, MultipartFile, etc.
  static String describeBody(Object? body) {
    if (body == null) return '';
    if (body is String) return _truncate(body);
    if (body is FormData) {
      final parts = <String>[];
      for (final field in body.fields) {
        parts.add('${field.key}=${_truncate(field.value)}');
      }
      for (final file in body.files) {
        final name = file.value.filename ?? 'file';
        parts.add('${file.key}=[multipart:$name]');
      }
      return 'FormData{${parts.join(', ')}}';
    }
    if (body is MultipartFile) {
      return 'MultipartFile(${body.filename ?? 'unnamed'})';
    }
    if (body is Map || body is List) {
      try {
        return _truncate(jsonEncode(body));
      } catch (_) {
        return body.toString();
      }
    }
    try {
      return _truncate(jsonEncode(body));
    } catch (_) {
      return body.toString();
    }
  }

  static void logApiCall(
    String method,
    String url,
    Map<String, String>? headers,
    Object? body,
  ) {
    if (!isDebugMode) return;
    debugPrint('[API] >>> $method $url');
    if (headers != null) {
      try {
        debugPrint('[API] Headers: ${jsonEncode(headers)}');
      } catch (_) {
        debugPrint('[API] Headers: $headers');
      }
    }
    if (body != null) {
      debugPrint('[API] Body: ${describeBody(body)}');
    }
  }

  static void logApiResponse(int statusCode, String body, [String? url]) {
    if (!isDebugMode) return;
    if (url != null) {
      debugPrint('[API] <<< $statusCode $url');
    } else {
      debugPrint('[API] <<< Response Status: $statusCode');
    }
    debugPrint('[API] Response Body: ${_truncate(body)}');
  }

  static String _truncate(String value, [int max = 2000]) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}…';
  }
}
