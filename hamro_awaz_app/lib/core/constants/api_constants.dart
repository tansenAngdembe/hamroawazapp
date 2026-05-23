class ApiConstants {
  /// Backend base URL (must match your Spring/server context path).
  ///
  /// Physical device (same Wi‑Fi as PC): your PC LAN IP, e.g. http://192.168.0.106:9080/api/v1
  /// Android emulator → host PC: http://10.0.2.2:9080/api/v1  ///
  static const String baseUrl = 'http://192.168.0.104:9080/api/v1';

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

  // Municipality / categories
  static const String categoryList = '/municipality/category/list';

  // Complaints
  static const String complaintCreate = '/user/complaint/create';
  static const String complaintUpdate = '/user/complaint/update';
  static const String complaintListNearby = '/user/complaint/list/nearBy';
  static const String complaintMyComplaintsList =
      '/user/complaint/myComplaints/list';

  // Comments
  static const String commentCreate = '/user/comment/create';
  static const String commentView = '/user/comment/view';
  static const String commentUpdate = '/user/comment/update';
  static const String commentDelete = '/user/comment/delete';

  /// Resolves relative media paths from the API (e.g. `/complaint/...jpg`).
  static String resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = Uri.parse(baseUrl);
    final origin = base.hasPort
        ? '${base.scheme}://${base.host}:${base.port}'
        : '${base.scheme}://${base.host}';
    return path.startsWith('/') ? '$origin$path' : '$origin/$path';
  }

  static const double defaultLatitude = 27.7172;
  static const double defaultLongitude = 85.3240;
}
