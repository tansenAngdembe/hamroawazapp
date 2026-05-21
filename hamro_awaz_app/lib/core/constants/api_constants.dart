class ApiConstants {
  /// Backend base URL (must match your Spring/server context path).
  ///
  /// Physical device (same Wi‑Fi as PC): your PC LAN IP, e.g. http://192.168.0.106:9080/api/v1
  /// Android emulator → host PC: http://10.0.2.2:9080/api/v1
  static const String baseUrl = 'http://192.168.1.77:9080/api/v1';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 60);

  static Uri uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }

  static String get loginUrl => uri(login).toString();

  // Auth / user
  static const String login = '/login';
  static const String signup = '/user/create';
  static const String verifyAccountOtp = '/user/account/verify';
  static const String checkAuth = '/checkAuth';
  static const String logout = '/logout';
  static const String profile = '/user/profile';

  // Document verification
  static const String documentUpload = '/user/document/UPLOAD';

  // Complaints
  static const String complaintCreate = '/user/complaint/create';
  static const String complaintUpdate = '/user/complaint/update';
  static const String complaintListNearby = '/user/complaint/list/nearBy';

  static const double defaultLatitude = 27.7172;
  static const double defaultLongitude = 85.3240;
}
