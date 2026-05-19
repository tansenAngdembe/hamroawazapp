import 'dart:convert';

/// Helpers for the backend standard JSON envelope:
/// `{ httpStatus, message, code, data, timestamp, asyncRequest }`
class ApiEnvelope {
  static Map<String, dynamic>? tryDecodeMap(String body) {
    if (body.isEmpty) return null;
    try {
      final v = jsonDecode(body);
      if (v is Map<String, dynamic>) return v;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Treat as success when HTTP layer is OK and body does not report an error status.
  static bool indicatesSuccess(Map<String, dynamic> body) {
    final httpStatus = body['httpStatus']?.toString().toUpperCase();
    if (httpStatus != null &&
        (httpStatus.contains('BAD_REQUEST') ||
            httpStatus.contains('UNAUTHORIZED') ||
            httpStatus.contains('FORBIDDEN') ||
            httpStatus.contains('ERROR'))) {
      return false;
    }
    final code = body['code'];
    if (code is int && (code == 400 || code == 401 || code == 403 || code == 422)) {
      return false;
    }
    return true;
  }

  static String message(Map<String, dynamic> body) =>
      body['message']?.toString() ?? 'Request completed';

  static dynamic data(Map<String, dynamic> body) => body['data'];
}
