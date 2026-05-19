import 'dart:convert';

class DebugHelper {
  static bool get isDebugMode => 
      const bool.fromEnvironment('dart.vm.product') == false;

  static void log(String message, [Object? data]) {
    if (isDebugMode) {
      print('[DEBUG] $message');
      if (data != null) {
        if (data is Map || data is List) {
          print('[DEBUG] Data: ${jsonEncode(data)}');
        } else {
          print('[DEBUG] Data: $data');
        }
      }
    }
  }

  static void logError(String message, [Object? error, StackTrace? stackTrace]) {
    if (isDebugMode) {
      print('[ERROR] $message');
      if (error != null) {
        print('[ERROR] Error: $error');
      }
      if (stackTrace != null) {
        print('[ERROR] Stack trace: $stackTrace');
      }
    }
  }

  static void logApiCall(String method, String url, Map<String, String>? headers, Object? body) {
    if (isDebugMode) {
      print('[API] $method $url');
      if (headers != null) {
        print('[API] Headers: ${jsonEncode(headers)}');
      }
      if (body != null) {
        if (body is String) {
          print('[API] Body: $body');
        } else {
          print('[API] Body: ${jsonEncode(body)}');
        }
      }
    }
  }

  static void logApiResponse(int statusCode, String body) {
    if (isDebugMode) {
      print('[API] Response Status: $statusCode');
      print('[API] Response Body: $body');
    }
  }
}