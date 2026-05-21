import 'dart:convert';

import 'package:flutter/foundation.dart';

class DebugHelper {
  /// Always log API traffic in debug/profile; never in release.
  static bool get isDebugMode => !kReleaseMode;

  static void log(String message, [Object? data]) {
    if (!isDebugMode) return;
    debugPrint('[DEBUG] $message');
    if (data != null) {
      if (data is Map || data is List) {
        debugPrint('[DEBUG] Data: ${jsonEncode(data)}');
      } else {
        debugPrint('[DEBUG] Data: $data');
      }
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

  static void logApiCall(
    String method,
    String url,
    Map<String, String>? headers,
    Object? body,
  ) {
    if (!isDebugMode) return;
    debugPrint('[API] >>> $method $url');
    if (headers != null) {
      debugPrint('[API] Headers: ${jsonEncode(headers)}');
    }
    if (body != null) {
      if (body is String) {
        debugPrint('[API] Body: $body');
      } else {
        debugPrint('[API] Body: ${jsonEncode(body)}');
      }
    }
  }

  static void logApiResponse(int statusCode, String body, [String? url]) {
    if (!isDebugMode) return;
    if (url != null) {
      debugPrint('[API] <<< $statusCode $url');
    } else {
      debugPrint('[API] <<< Response Status: $statusCode');
    }
    debugPrint('[API] Response Body: $body');
  }
}
