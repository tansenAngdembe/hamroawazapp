import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../core/api/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../core/utils/api_envelope.dart';
import '../core/utils/debug_helper.dart';
import '../models/api_response.dart';
import '../models/complaint.dart';
import '../models/create_complaint_request.dart';
import '../services/auth_service.dart';

class ComplaintRepository {
  ComplaintRepository({
    required DioClient dioClient,
    required AuthService authService,
  })  : _dio = dioClient,
        _auth = authService;

  final DioClient _dio;
  final AuthService _auth;

  Future<ApiResponse<Complaint>> createComplaint({
    required CreateComplaintRequest request,
    File? photo,
  }) async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) {
      return ApiResponse<Complaint>(
        success: false,
        message: 'Please log in to submit a complaint',
      );
    }

    try {
      final dataJson = jsonEncode(request.toJson());

      // Spring @RequestPart("data") expects a part with Content-Type: application/json.
      final formData = FormData();
      formData.files.add(
        MapEntry(
          'data',
          MultipartFile.fromString(
            dataJson,
            filename: 'data.json',
            contentType: MediaType.parse('application/json'),
          ),
        ),
      );

      if (photo != null && await photo.exists()) {
        final ext = photo.path.split('.').last.toLowerCase();
        final isPng = ext == 'png';
        formData.files.add(
          MapEntry(
            'photos',
            await MultipartFile.fromFile(
              photo.path,
              filename: isPng ? 'complaint_photo.png' : 'complaint_photo.jpg',
              contentType: MediaType('image', isPng ? 'png' : 'jpeg'),
            ),
          ),
        );
      }

      final response = await _dio.dio.post(
        ApiConstants.complaintCreate,
        data: formData,
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 90),
        ),
      );

      return await _parseComplaintResponse(response, request, photo);
    } on DioException catch (e, st) {
      DebugHelper.logError('createComplaint Dio error', e, st);
      return ApiResponse<Complaint>(
        success: false,
        message: _dio.messageFromError(e),
      );
    } catch (e, st) {
      DebugHelper.logError('createComplaint error', e, st);
      return ApiResponse<Complaint>(
        success: false,
        message: 'Failed to create complaint: $e',
      );
    }
  }

  Future<ApiResponse<Complaint>> _parseComplaintResponse(
    Response<dynamic> response,
    CreateComplaintRequest request,
    File? photo,
  ) async {
    final status = response.statusCode ?? 0;
    final body = response.data;

    Map<String, dynamic>? map;
    if (body is Map<String, dynamic>) {
      map = body;
    } else if (body is String && body.isNotEmpty) {
      map = ApiEnvelope.tryDecodeMap(body);
    }

    if (map == null) {
      return ApiResponse<Complaint>(
        success: false,
        message: 'Invalid server response',
      );
    }

    if (status != 200 && status != 201) {
      return ApiResponse<Complaint>(
        success: false,
        message: ApiEnvelope.message(map),
        raw: map,
      );
    }

    if (!ApiEnvelope.indicatesSuccess(map)) {
      return ApiResponse<Complaint>(
        success: false,
        message: ApiEnvelope.message(map),
        raw: map,
      );
    }

    final data = ApiEnvelope.data(map);
    final storedUser = await _auth.getStoredUser();
    final currentUserId = storedUser?.id ?? '';

    Complaint? complaint;
    if (data is Map) {
      complaint = Complaint.fromApiMap(
        Map<String, dynamic>.from(data),
        currentUserId: currentUserId,
      );
    }

    complaint ??= Complaint(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: request.complaintTitle,
      description: request.complaintDescription,
      category: complaintCategoryFromApiId(request.categoryId),
      department: '',
      status: ComplaintStatus.pending,
      userId: currentUserId.isEmpty ? '0' : currentUserId,
      latitude: request.complaintCoordinates.latitude,
      longitude: request.complaintCoordinates.longitude,
      createdAt: DateTime.now(),
      isOwnSubmission: true,
      categoryIdStr: request.categoryId,
    );

    return ApiResponse<Complaint>(
      success: true,
      message: ApiEnvelope.message(map),
      data: complaint,
      raw: map,
    );
  }
}
