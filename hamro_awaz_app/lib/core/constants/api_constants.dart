class ApiConstants {
  static const String baseUrl = "http://192.168.1.77:9080/api/v1";
  // static const String baseUrl = "http://localhost:9080/api/v1";

  // Auth endpoints
  static const String login = "/login";
  static const String signup = "/user/create";
  static const String verifyAccountOtp = "/user/account/verify";
  static const String checkAuth = "/checkAuth";
  static const String logout = "/logout";
  static const String profile = "/user/profile";

  // Complaint endpoints (Complaint Controller)
  static const String complaintCreate = "/user/complaint/create";
  static const String complaintUpdate = "/user/complaint/update";
  static const String complaintListNearby = "/user/complaint/list/nearBy";

  /// Default map center (Kathmandu) when device location is not used.
  static const double defaultLatitude = 27.7172;
  static const double defaultLongitude = 85.3240;
}

