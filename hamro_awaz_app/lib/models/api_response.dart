import '../core/utils/api_envelope.dart';

/// Parsed backend envelope `{ httpStatus, message, code, data, ... }`.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.code,
    this.data,
    this.raw,
  });

  final bool success;
  final String message;
  final int? code;
  final T? data;
  final Map<String, dynamic>? raw;

  static ApiResponse<T> fromJson<T>(
    Map<String, dynamic> json,
    T? Function(dynamic data) parseData,
  ) {
    final ok = ApiEnvelope.indicatesSuccess(json);
    return ApiResponse<T>(
      success: ok,
      message: ApiEnvelope.message(json),
      code: json['code'] is int ? json['code'] as int : int.tryParse('${json['code']}'),
      data: ok ? parseData(ApiEnvelope.data(json)) : null,
      raw: json,
    );
  }
}
