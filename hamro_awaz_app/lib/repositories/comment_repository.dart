import 'package:dio/dio.dart';

import '../core/api/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../core/utils/api_envelope.dart';
import '../core/utils/debug_helper.dart';
import '../models/api_response.dart';
import '../models/comment_models.dart';
import '../services/auth_service.dart';

class CommentRepository {
  CommentRepository({
    required DioClient dioClient,
    required AuthService authService,
  })  : _dio = dioClient,
        _auth = authService;

  final DioClient _dio;
  final AuthService _auth;

  Future<ApiResponse<void>> _ensureAuth() async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) {
      return const ApiResponse<void>(
        success: false,
        message: 'Please log in to continue',
      );
    }
    return const ApiResponse<void>(success: true, message: '');
  }

  Map<String, dynamic>? _parseBody(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is String && body.isNotEmpty) {
      return ApiEnvelope.tryDecodeMap(body);
    }
    return null;
  }

  ApiResponse<T> _fromResponse<T>(
    Response<dynamic> response,
    T? Function(dynamic data)? parseData,
  ) {
    final status = response.statusCode ?? 0;
    final map = _parseBody(response.data);

    if (map == null) {
      return ApiResponse<T>(
        success: false,
        message: 'Invalid server response',
      );
    }

    if (status != 200 && status != 201) {
      return ApiResponse<T>(
        success: false,
        message: ApiEnvelope.message(map),
        raw: map,
      );
    }

    if (!ApiEnvelope.indicatesSuccess(map)) {
      return ApiResponse<T>(
        success: false,
        message: ApiEnvelope.message(map),
        raw: map,
      );
    }

    final data = parseData != null ? parseData(ApiEnvelope.data(map)) : null;
    return ApiResponse<T>(
      success: true,
      message: ApiEnvelope.message(map),
      data: data,
      raw: map,
    );
  }

  Future<ApiResponse<void>> createComment(CreateCommentRequest request) async {
    final auth = await _ensureAuth();
    if (!auth.success) return auth;

    try {
      final response = await _dio.dio.post(
        ApiConstants.commentCreate,
        data: request.toJson(),
      );
      return _fromResponse<void>(response, null);
    } on DioException catch (e, st) {
      DebugHelper.logError('createComment', e, st);
      return ApiResponse<void>(
        success: false,
        message: _dio.messageFromError(e),
      );
    } catch (e, st) {
      DebugHelper.logError('createComment', e, st);
      return ApiResponse<void>(
        success: false,
        message: 'Failed to post comment: $e',
      );
    }
  }

  Future<ApiResponse<List<ComplaintComment>>> viewComments(
    ViewCommentsRequest request,
  ) async {
    final auth = await _ensureAuth();
    if (!auth.success) {
      return ApiResponse<List<ComplaintComment>>(
        success: false,
        message: auth.message,
      );
    }

    try {
      final response = await _dio.dio.post(
        ApiConstants.commentView,
        data: request.toJson(),
      );
      return _fromResponse<List<ComplaintComment>>(
        response,
        (data) => ComplaintComment.listFromData(data),
      );
    } on DioException catch (e, st) {
      DebugHelper.logError('viewComments', e, st);
      return ApiResponse<List<ComplaintComment>>(
        success: false,
        message: _dio.messageFromError(e),
      );
    } catch (e, st) {
      DebugHelper.logError('viewComments', e, st);
      return ApiResponse<List<ComplaintComment>>(
        success: false,
        message: 'Failed to load comments: $e',
      );
    }
  }

  Future<ApiResponse<void>> updateComment(UpdateCommentRequest request) async {
    final auth = await _ensureAuth();
    if (!auth.success) return auth;

    try {
      final response = await _dio.dio.post(
        ApiConstants.commentUpdate,
        data: request.toJson(),
      );
      return _fromResponse<void>(response, null);
    } on DioException catch (e, st) {
      DebugHelper.logError('updateComment', e, st);
      return ApiResponse<void>(
        success: false,
        message: _dio.messageFromError(e),
      );
    } catch (e, st) {
      DebugHelper.logError('updateComment', e, st);
      return ApiResponse<void>(
        success: false,
        message: 'Failed to update comment: $e',
      );
    }
  }

  Future<ApiResponse<void>> deleteComment(DeleteCommentRequest request) async {
    final auth = await _ensureAuth();
    if (!auth.success) return auth;

    try {
      final response = await _dio.dio.post(
        ApiConstants.commentDelete,
        data: request.toJson(),
      );
      return _fromResponse<void>(response, null);
    } on DioException catch (e, st) {
      DebugHelper.logError('deleteComment', e, st);
      return ApiResponse<void>(
        success: false,
        message: _dio.messageFromError(e),
      );
    } catch (e, st) {
      DebugHelper.logError('deleteComment', e, st);
      return ApiResponse<void>(
        success: false,
        message: 'Failed to delete comment: $e',
      );
    }
  }
}
