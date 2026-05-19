import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/api_envelope.dart';
import '../../../core/utils/debug_helper.dart';
import '../../../services/auth_service.dart';
import '../domain/nearby_complaint_filter_status.dart';
import 'models/nearby_complaint_models.dart';

/// Thrown when the nearby complaints API returns an error or invalid payload.
class NearbyComplaintsApiException implements Exception {
  NearbyComplaintsApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// HTTP client for `POST /user/complaint/list/nearBy` with the standard envelope.
class NearbyComplaintsApiService {
  NearbyComplaintsApiService({required AuthService authService})
      : _auth = authService;

  final AuthService _auth;

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await _auth.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Request body matches backend contract. [categoryId] is always null for now.
  Future<NearbyComplaintsListDataDto> fetchNearbyComplaints({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required NearbyComplaintFilterStatus statusFilter,
  }) async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.complaintListNearby}');
    final headers = await _headers();

    final bodyMap = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
      'statusId': statusFilter.backendStatusId,
      'categoryId': null,
    };
    final body = jsonEncode(bodyMap);

    DebugHelper.logApiCall('POST', uri.toString(), headers, bodyMap);

    final response = await http
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));

    DebugHelper.logApiResponse(response.statusCode, response.body);

    final map = ApiEnvelope.tryDecodeMap(response.body);
    if (map == null) {
      throw NearbyComplaintsApiException('Invalid response from server');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw NearbyComplaintsApiException(
        map['message']?.toString() ??
            'Request failed (${response.statusCode})',
      );
    }

    if (!ApiEnvelope.indicatesSuccess(map)) {
      throw NearbyComplaintsApiException(ApiEnvelope.message(map));
    }

    final dataRaw = ApiEnvelope.data(map);
    if (dataRaw is! Map) {
      return const NearbyComplaintsListDataDto(complaints: []);
    }

    final data = Map<String, dynamic>.from(dataRaw);
    return NearbyComplaintsListDataDto.fromDataJson(data);
  }
}
