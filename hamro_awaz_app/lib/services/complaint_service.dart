import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../core/utils/api_envelope.dart';
import '../core/utils/debug_helper.dart';
import '../models/complaint.dart';
import '../models/search_param.dart';
import 'auth_service.dart';

class ComplaintService {
  ComplaintService({required AuthService authService}) : _auth = authService;

  final AuthService _auth;
  static const String _cacheKey = 'cached_my_complaints';

  Future<Map<String, String>> _jsonHeaders({bool withAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await _auth.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<void> _saveToLocalCache(Complaint complaint) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await _loadLocalCache();
    existing.removeWhere((c) => c.id == complaint.id);
    existing.insert(0, complaint);
    await prefs.setString(
      _cacheKey,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<Complaint>> _loadLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Complaint.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<Complaint> _extractComplaintListFromData(dynamic data, String currentUserId) {
    if (data == null) return [];
    List<dynamic> rawList = [];
    if (data is List) {
      rawList = data;
    } else if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      for (final key in ['complaints', 'content', 'items', 'data', 'records']) {
        final v = m[key];
        if (v is List) {
          rawList = v;
          break;
        }
      }
    }
    final out = <Complaint>[];
    for (final item in rawList) {
      if (item is Map) {
        out.add(Complaint.fromApiMap(
          Map<String, dynamic>.from(item),
          currentUserId: currentUserId,
        ));
      }
    }
    return out;
  }

  Complaint? _complaintFromCreateOrUpdateData(dynamic data, String currentUserId) {
    if (data == null) return null;
    if (data is Map) {
      return Complaint.fromApiMap(
        Map<String, dynamic>.from(data),
        currentUserId: currentUserId,
      );
    }
    return null;
  }

  /// Persist a complaint locally after successful API create.
  Future<void> cacheComplaintLocally(Complaint complaint) async {
    await _saveToLocalCache(complaint);
  }

  /// `POST /user/complaint/myComplaints/list` with [SearchParam] body.
  Future<MyComplaintsPageResult> listMyComplaints({
    SearchParam? searchParam,
  }) async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please log in to view your complaints');
    }

    final param = searchParam ?? SearchParam.defaults();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.complaintMyComplaintsList}',
    );
    final headers = await _jsonHeaders(withAuth: true);
    final body = jsonEncode(param.toJson());

    DebugHelper.logApiCall('POST', url.toString(), headers, param.toJson());

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      DebugHelper.logApiResponse(response.statusCode, response.body, url.toString());

      final map = ApiEnvelope.tryDecodeMap(response.body);
      if (map == null) {
        throw Exception('Invalid my complaints response');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          map['message']?.toString() ??
              'Failed to load complaints (${response.statusCode})',
        );
      }

      if (!ApiEnvelope.indicatesSuccess(map)) {
        throw Exception(ApiEnvelope.message(map));
      }

      final data = ApiEnvelope.data(map);
      if (data is! Map) {
        return const MyComplaintsPageResult(total: 0, records: []);
      }

      final page = Map<String, dynamic>.from(data);
      final total = (page['total'] as num?)?.toInt() ?? 0;
      final rawRecords = page['records'];
      final storedUser = await _auth.getStoredUser();
      final currentUserId = storedUser?.id ?? '';

      final records = <Complaint>[];
      if (rawRecords is List) {
        for (final item in rawRecords) {
          if (item is Map) {
            records.add(
              Complaint.fromApiMap(
                Map<String, dynamic>.from(item),
                currentUserId: currentUserId,
                markAsOwnSubmission: true,
              ),
            );
          }
        }
      }

      return MyComplaintsPageResult(total: total, records: records);
    } on TimeoutException {
      throw Exception('My complaints request timed out');
    } on http.ClientException catch (e) {
      throw Exception('Could not load complaints: ${e.message}');
    }
  }

  /// Loads the current user's complaints from the backend.
  Future<List<Complaint>> getComplaints({SearchParam? searchParam}) async {
    final page = await listMyComplaints(searchParam: searchParam);
    return page.records;
  }

  /// `GET /municipality/category/list` — returns parsed categories from envelope `data`.
  Future<List<Category>> getCategories() async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please log in to load categories');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.categoryList}');
    final headers = await _jsonHeaders(withAuth: true);

    DebugHelper.logApiCall('GET', url.toString(), headers, null);

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      DebugHelper.logApiResponse(response.statusCode, response.body, url.toString());

      final map = ApiEnvelope.tryDecodeMap(response.body);
      if (map == null) {
        throw Exception('Invalid category list response');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          map['message']?.toString() ?? 'Failed to load categories (${response.statusCode})',
        );
      }

      if (!ApiEnvelope.indicatesSuccess(map)) {
        throw Exception(ApiEnvelope.message(map));
      }

      final categories = Category.listFromEnvelopeData(ApiEnvelope.data(map));
      if (categories.isEmpty) {
        throw Exception('No categories available');
      }

      return categories;
    } on TimeoutException {
      throw Exception('Category list request timed out');
    } on http.ClientException catch (e) {
      throw Exception('Could not load categories: ${e.message}');
    }
  }

  /// Nearby complaints; [withAuth] sends bearer token when available for personalized/highlighted results.
  Future<List<Complaint>> getComplaintsForMap({
    double? latitude,
    double? longitude,
    double radiusKm = 0.1,
    Map<String, dynamic>? searchParam,
    bool withAuth = true,
  }) async {
    final user = await _auth.getStoredUser();
    final lat = latitude ?? ApiConstants.defaultLatitude;
    final lng = longitude ?? ApiConstants.defaultLongitude;

    var uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.complaintListNearby}');
    if (searchParam != null) {
      uri = uri.replace(
        queryParameters: {
          'searchParam': jsonEncode(searchParam),
        },
      );
    }

    final headers = await _jsonHeaders(withAuth: false);
    if (withAuth) {
      final token = await _auth.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final body = jsonEncode({
      'latitude': lat,
      'longitude': lng,
      'radiusKm': radiusKm < 0.1 ? 0.1 : radiusKm,
      'statusId': 'ACTIVE',
      'categoryId': null,
    });

    DebugHelper.logApiCall('POST', uri.toString(), headers, body);

    final response = await http
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));

    DebugHelper.logApiResponse(response.statusCode, response.body);

    final map = ApiEnvelope.tryDecodeMap(response.body);
    if (map == null) {
      throw Exception('Invalid response from list/nearBy');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(map['message']?.toString() ?? 'list/nearBy failed');
    }

    if (!ApiEnvelope.indicatesSuccess(map)) {
      throw Exception(ApiEnvelope.message(map));
    }

    final userId = user?.id ?? '';
    return _extractComplaintListFromData(ApiEnvelope.data(map), userId);
  }

  Future<Map<String, dynamic>> createComplaint({
    required String title,
    required String description,
    required String categoryId,
    required double latitude,
    required double longitude,
    List<File> imageFiles = const [],
    String? categoryLabel,
  }) async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Please log in to submit a complaint'};
    }

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.complaintCreate}');

    final dataObject = <String, dynamic>{
      'complaintTitle': title,
      'complaintDescription': description,
      'categoryId': categoryId,
      'complaintCoordinates': {
        'latitude': latitude,
        'longitude': longitude,
      },
    };
    final dataJson = jsonEncode(dataObject);

    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // @RequestPart("data") — JSON part with explicit application/json.
    request.files.add(
      http.MultipartFile.fromString(
        'data',
        dataJson,
        filename: 'data.json',
        contentType: MediaType('application', 'json'),
      ),
    );

    for (final file in imageFiles) {
      if (!await file.exists()) continue;
      final ext = file.path.split('.').last.toLowerCase();
      final isPng = ext == 'png';
      request.files.add(
        await http.MultipartFile.fromPath(
          'photos',
          file.path,
          filename: isPng ? 'complaint_photo.png' : 'complaint_photo.jpg',
          contentType: MediaType('image', isPng ? 'png' : 'jpeg'),
        ),
      );
    }

    DebugHelper.logApiCall('POST', url.toString(), request.headers, {
      'data': dataObject,
      'photos': imageFiles.isEmpty
          ? null
          : imageFiles.map((f) => f.path).toList(),
    });

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);

      DebugHelper.logApiResponse(response.statusCode, response.body, url.toString());

      final map = ApiEnvelope.tryDecodeMap(response.body);
      if (map == null) {
        return {'success': false, 'message': 'Invalid server response'};
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        return {
          'success': false,
          'message': map['message']?.toString() ?? 'Create failed',
        };
      }

      if (!ApiEnvelope.indicatesSuccess(map)) {
        return {'success': false, 'message': ApiEnvelope.message(map)};
      }

      final storedUser = await _auth.getStoredUser();
      final currentUserId = storedUser?.id ?? '';
      final parsed =
          _complaintFromCreateOrUpdateData(ApiEnvelope.data(map), currentUserId);

      final complaint = parsed ??
          Complaint(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            description: description,
            category: complaintCategoryFromApiId(categoryId),
            department: '',
            status: ComplaintStatus.pending,
            userId: currentUserId.isEmpty ? '0' : currentUserId,
            latitude: latitude,
            longitude: longitude,
            createdAt: DateTime.now(),
            isOwnSubmission: true,
            categoryIdStr: categoryId,
            categoryLabel: categoryLabel,
          );

      final toStore = complaint.copyWith(
        userId: currentUserId.isEmpty ? complaint.userId : currentUserId,
        isOwnSubmission: true,
        categoryLabel: categoryLabel ?? complaint.categoryLabel,
      );
      await _saveToLocalCache(toStore);

      return {
        'success': true,
        'message': ApiEnvelope.message(map),
        'complaint': toStore,
        'raw': map,
      };
    } on TimeoutException {
      return {'success': false, 'message': 'Complaint submission timed out'};
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'message': 'Could not submit complaint: ${e.message}',
      };
    }
  }

  Future<Map<String, dynamic>> updateComplaint({
    required String complaintUniqueId,
    String? complaintTitle,
    String? complaintDescription,
    String? photoUrl,
    String? categoryId,
    File? photoFile,
  }) async {
    final token = await _auth.getAccessToken();
    if (token == null) {
      return {'success': false, 'message': 'Please log in to update a complaint'};
    }

    final baseUri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.complaintUpdate}');

    if (photoFile != null) {
      final request = http.MultipartRequest('POST', baseUri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['complaintUniqueId'] = complaintUniqueId;
      if (complaintTitle != null) request.fields['complaintTitle'] = complaintTitle;
      if (complaintDescription != null) {
        request.fields['complaintDescription'] = complaintDescription;
      }
      if (photoUrl != null) request.fields['photoUrl'] = photoUrl;
      if (categoryId != null) request.fields['categoryId'] = categoryId;
      request.files.add(
        await http.MultipartFile.fromPath('photos', photoFile.path),
      );

      DebugHelper.logApiCall('POST', baseUri.toString(), request.headers, request.fields);

      final streamed = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);
      DebugHelper.logApiResponse(response.statusCode, response.body);
      return _handleUpdateResponse(
        response,
        complaintUniqueId,
        complaintTitle: complaintTitle,
        complaintDescription: complaintDescription,
        photoUrl: photoUrl,
        categoryId: categoryId,
      );
    }

    final url = baseUri;
    final bodyMap = <String, dynamic>{
      'complaintUniqueId': complaintUniqueId,
    };
    if (complaintTitle != null) bodyMap['complaintTitle'] = complaintTitle;
    if (complaintDescription != null) {
      bodyMap['complaintDescription'] = complaintDescription;
    }
    if (photoUrl != null) bodyMap['photoUrl'] = photoUrl;
    if (categoryId != null) bodyMap['categoryId'] = categoryId;

    final headers = await _jsonHeaders(withAuth: true);
    headers['Authorization'] = 'Bearer $token';
    final body = jsonEncode(bodyMap);
    DebugHelper.logApiCall('POST', url.toString(), headers, body);

    final response = await http
        .post(url, headers: headers, body: body)
        .timeout(const Duration(seconds: 30));

    DebugHelper.logApiResponse(response.statusCode, response.body);
    return _handleUpdateResponse(
      response,
      complaintUniqueId,
      complaintTitle: complaintTitle,
      complaintDescription: complaintDescription,
      photoUrl: photoUrl,
      categoryId: categoryId,
    );
  }

  Future<Map<String, dynamic>> _handleUpdateResponse(
    http.Response response,
    String complaintUniqueId, {
    String? complaintTitle,
    String? complaintDescription,
    String? photoUrl,
    String? categoryId,
  }) async {
    final map = ApiEnvelope.tryDecodeMap(response.body);
    if (map == null) {
      return {'success': false, 'message': 'Invalid server response'};
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      return {
        'success': false,
        'message': map['message']?.toString() ?? 'Update failed',
      };
    }

    if (!ApiEnvelope.indicatesSuccess(map)) {
      return {'success': false, 'message': ApiEnvelope.message(map)};
    }

    final user = await _auth.getStoredUser();
    final uid = user?.id ?? '';
    final parsed = _complaintFromCreateOrUpdateData(ApiEnvelope.data(map), uid);

    if (parsed != null) {
      await _saveToLocalCache(parsed);
    } else {
      final cached = await _loadLocalCache();
      final idx = cached.indexWhere((c) => c.id == complaintUniqueId);
      if (idx >= 0) {
        var c = cached[idx];
        if (complaintTitle != null) c = c.copyWith(title: complaintTitle);
        if (complaintDescription != null) {
          c = c.copyWith(description: complaintDescription);
        }
        if (photoUrl != null) {
          c = c.copyWith(imageUrls: [...c.imageUrls, photoUrl]);
        }
        if (categoryId != null) {
          c = c.copyWith(
            category: complaintCategoryFromApiId(categoryId),
            categoryIdStr: categoryId,
          );
        }
        c = c.copyWith(updatedAt: DateTime.now());
        await _saveToLocalCache(c);
      }
    }

    return {
      'success': true,
      'message': ApiEnvelope.message(map),
      'complaint': parsed,
      'raw': map,
    };
  }

  Future<bool> voteComplaint(String complaintId, String userId, bool isYes) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
