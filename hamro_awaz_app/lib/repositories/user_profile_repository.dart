import 'package:dio/dio.dart';

import '../core/api/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../core/utils/api_envelope.dart';
import '../core/utils/debug_helper.dart';
import '../models/api_response.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class UserProfileRepository {
  UserProfileRepository({
    required DioClient dioClient,
    required AuthService authService,
  })  : _dio = dioClient,
        _auth = authService;

  final DioClient _dio;
  final AuthService _auth;

  /// GET `/api/v1/user/profile` — falls back to POST if GET is not supported.
  Future<ApiResponse<UserProfile>> fetchProfile() async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) {
      return const ApiResponse<UserProfile>(
        success: false,
        message: 'Please log in again',
      );
    }

    try {
      final getResponse = await _dio.dio.get(ApiConstants.profile);
      final parsed = _parseResponse(getResponse);
      if (parsed.success) return parsed;

      DebugHelper.log('GET profile failed, trying POST fallback');
      final postResponse = await _dio.dio.post(ApiConstants.profile);
      return _parseResponse(postResponse);
    } on DioException catch (e) {
      if (e.response?.statusCode == 405 || e.response?.statusCode == 404) {
        try {
          final postResponse = await _dio.dio.post(ApiConstants.profile);
          return _parseResponse(postResponse);
        } on DioException catch (e2) {
          return ApiResponse<UserProfile>(
            success: false,
            message: _dio.messageFromError(e2),
          );
        }
      }
      return ApiResponse<UserProfile>(
        success: false,
        message: _dio.messageFromError(e),
      );
    } catch (e, st) {
      DebugHelper.logError('fetchProfile unexpected error', e, st);
      return ApiResponse<UserProfile>(
        success: false,
        message: 'Could not load profile: $e',
      );
    }
  }

  ApiResponse<UserProfile> _parseResponse(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final body = response.data;

    Map<String, dynamic>? map;
    if (body is Map<String, dynamic>) {
      map = body;
    } else if (body is String && body.isNotEmpty) {
      map = ApiEnvelope.tryDecodeMap(body);
    }

    if (map == null) {
      return ApiResponse<UserProfile>(
        success: false,
        message: 'Invalid profile response',
      );
    }

    if (status != 200 && status != 201) {
      return ApiResponse<UserProfile>(
        success: false,
        message: ApiEnvelope.message(map),
        raw: map,
      );
    }

    final envelope = ApiResponse.fromJson<UserProfile>(
      map,
      (data) {
        if (data is Map<String, dynamic>) {
          return UserProfile.fromJson(data);
        }
        if (data is Map) {
          return UserProfile.fromJson(Map<String, dynamic>.from(data));
        }
        return null;
      },
    );
    return envelope;
  }
}
