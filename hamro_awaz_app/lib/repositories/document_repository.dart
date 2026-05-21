import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../core/api/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../core/utils/api_envelope.dart';
import '../core/utils/debug_helper.dart';
import '../models/api_response.dart';
import '../models/upload_document_request.dart';
import '../services/auth_service.dart';

class DocumentRepository {
  DocumentRepository({
    required DioClient dioClient,
    required AuthService authService,
  })  : _dio = dioClient,
        _auth = authService;

  final DioClient _dio;
  final AuthService _auth;

  Future<ApiResponse<void>> uploadDocuments({
    required UploadDocumentRequest request,
    required File citizenshipFront,
    required File citizenshipBack,
  }) async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) {
      return const ApiResponse<void>(
        success: false,
        message: 'Please log in to upload documents',
      );
    }

    try {
      final dataJson = jsonEncode(request.toJson());
      final formData = FormData.fromMap({
        'data': MultipartFile.fromString(
          dataJson,
          filename: 'data.json',
          contentType: MediaType.parse('application/json'),
        ),
        'citizenshipFront': await MultipartFile.fromFile(
          citizenshipFront.path,
          filename: 'citizenship_front.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
        'citizenshipBack': await MultipartFile.fromFile(
          citizenshipBack.path,
          filename: 'citizenship_back.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await _dio.dio.post(
        ApiConstants.documentUpload,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 90),
        ),
      );

      return _parseVoidResponse(response);
    } on DioException catch (e, st) {
      DebugHelper.logError('uploadDocuments Dio error', e, st);
      return ApiResponse<void>(
        success: false,
        message: _dio.messageFromError(e),
      );
    } catch (e, st) {
      DebugHelper.logError('uploadDocuments error', e, st);
      return ApiResponse<void>(
        success: false,
        message: 'Upload failed: $e',
      );
    }
  }

  ApiResponse<void> _parseVoidResponse(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    final body = response.data;

    Map<String, dynamic>? map;
    if (body is Map<String, dynamic>) {
      map = body;
    } else if (body is String && body.isNotEmpty) {
      map = ApiEnvelope.tryDecodeMap(body);
    }

    if (map == null) {
      if (status == 200 || status == 201) {
        return const ApiResponse<void>(success: true, message: 'Documents uploaded');
      }
      return const ApiResponse<void>(success: false, message: 'Invalid server response');
    }

    return ApiResponse.fromJson<void>(map, (_) => null);
  }
}
