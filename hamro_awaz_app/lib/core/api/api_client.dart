import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../utils/debug_helper.dart';

/// Shared HTTP client for backend calls (uses package:http, not Dio).
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final ApiClient instance = ApiClient();

  Map<String, String> get defaultHeaders => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = ApiConstants.uri(path);
    final mergedHeaders = {...defaultHeaders, ...?headers};
    DebugHelper.logApiCall('GET', uri.toString(), mergedHeaders, null);

    try {
      final response = await _client
          .get(uri, headers: mergedHeaders)
          .timeout(timeout);
      DebugHelper.logApiResponse(response.statusCode, response.body, uri.toString());
      return response;
    } on TimeoutException catch (e, st) {
      DebugHelper.logError('GET timeout: ${uri.toString()}', e, st);
      rethrow;
    } on SocketException catch (e, st) {
      DebugHelper.logError('GET socket error: ${uri.toString()}', e, st);
      rethrow;
    } on http.ClientException catch (e, st) {
      DebugHelper.logError('GET client error: ${uri.toString()}', e, st);
      rethrow;
    }
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = ApiConstants.uri(path);
    final mergedHeaders = {...defaultHeaders, ...?headers};
    final encodedBody = body is String ? body : jsonEncode(body);
    DebugHelper.logApiCall('POST', uri.toString(), mergedHeaders, encodedBody);

    try {
      final response = await _client
          .post(uri, headers: mergedHeaders, body: encodedBody)
          .timeout(timeout);
      DebugHelper.logApiResponse(response.statusCode, response.body, uri.toString());
      return response;
    } on TimeoutException catch (e, st) {
      DebugHelper.logError('POST timeout: ${uri.toString()}', e, st);
      rethrow;
    } on SocketException catch (e, st) {
      DebugHelper.logError('POST socket error: ${uri.toString()}', e, st);
      rethrow;
    } on http.ClientException catch (e, st) {
      DebugHelper.logError('POST client error: ${uri.toString()}', e, st);
      rethrow;
    }
  }

  void close() => _client.close();
}
