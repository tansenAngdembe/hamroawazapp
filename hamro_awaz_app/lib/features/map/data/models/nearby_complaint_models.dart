import 'package:flutter/foundation.dart';

/// Status block returned for each nearby complaint.
@immutable
class NearbyComplaintStatusDto {
  const NearbyComplaintStatusDto({
    required this.name,
    this.description,
  });

  final String name;
  final String? description;

  factory NearbyComplaintStatusDto.fromJson(Map<String, dynamic> json) {
    return NearbyComplaintStatusDto(
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

/// Reporter summary on a nearby complaint.
@immutable
class NearbyComplaintReporterDto {
  const NearbyComplaintReporterDto({
    required this.fullName,
    this.phoneNumber,
    this.uniqueId,
    this.profilePictureLink,
  });

  final String fullName;
  final String? phoneNumber;
  final String? uniqueId;
  final String? profilePictureLink;

  factory NearbyComplaintReporterDto.fromJson(Map<String, dynamic> json) {
    return NearbyComplaintReporterDto(
      fullName: json['fullName']?.toString() ?? 'Unknown',
      phoneNumber: json['phoneNumber']?.toString(),
      uniqueId: json['uniqueId']?.toString(),
      profilePictureLink: json['profilePictureLink']?.toString(),
    );
  }
}

/// One row from `listNearByComplainsResponse`.
@immutable
class NearbyComplaintDto {
  const NearbyComplaintDto({
    required this.uniqueId,
    required this.complaintTitle,
    required this.complaintDescription,
    required this.status,
    required this.reportedBy,
    this.createdAt,
    this.latitude,
    this.longitude,
  });

  final String uniqueId;
  final String complaintTitle;
  final String complaintDescription;
  final NearbyComplaintStatusDto status;
  final NearbyComplaintReporterDto reportedBy;
  final DateTime? createdAt;
  final double? latitude;
  final double? longitude;

  static DateTime? _parseCreatedDate(dynamic raw) {
    if (raw is List && raw.length >= 6) {
      try {
        final y = (raw[0] as num).toInt();
        final mo = (raw[1] as num).toInt();
        final d = (raw[2] as num).toInt();
        final h = (raw[3] as num).toInt();
        final mi = (raw[4] as num).toInt();
        final s = (raw[5] as num).toInt();
        return DateTime(y, mo, d, h, mi, s);
      } catch (_) {
        return null;
      }
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        return DateTime.tryParse(raw);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static (double?, double?) _parseCoordinates(Map<String, dynamic> json) {
    final dynamic cc =
        json['complaintCoordinates'] ?? json['coordinates'] ?? json['location'];
    if (cc is Map) {
      final m = Map<String, dynamic>.from(cc);
      final lat = (m['latitude'] ?? m['lat']) as num?;
      final lng = (m['longitude'] ?? m['lng']) as num?;
      return (lat?.toDouble(), lng?.toDouble());
    }
    final lat = json['latitude'] as num?;
    final lng = json['longitude'] as num?;
    return (lat?.toDouble(), lng?.toDouble());
  }

  factory NearbyComplaintDto.fromJson(Map<String, dynamic> json) {
    final statusMap = json['status'];
    final reporterMap = json['reportedBy'];
    final coords = _parseCoordinates(json);

    return NearbyComplaintDto(
      uniqueId: json['uniqueId']?.toString() ?? '',
      complaintTitle: json['complaintTitle']?.toString() ?? '',
      complaintDescription: json['complaintDescription']?.toString() ?? '',
      status: statusMap is Map
          ? NearbyComplaintStatusDto.fromJson(
              Map<String, dynamic>.from(statusMap),
            )
          : const NearbyComplaintStatusDto(name: ''),
      reportedBy: reporterMap is Map
          ? NearbyComplaintReporterDto.fromJson(
              Map<String, dynamic>.from(reporterMap),
            )
          : const NearbyComplaintReporterDto(fullName: 'Unknown'),
      createdAt: _parseCreatedDate(json['createdDate']),
      latitude: coords.$1,
      longitude: coords.$2,
    );
  }
}

/// Parsed `data` section for nearby list API.
@immutable
class NearbyComplaintsListDataDto {
  const NearbyComplaintsListDataDto({
    required this.complaints,
    this.count,
  });

  final List<NearbyComplaintDto> complaints;
  final int? count;

  static List<dynamic> _extractList(Map<String, dynamic> data) {
    final primary = data['listNearByComplainsResponse'];
    if (primary is List) return primary;
    final alt = data['listNearbyComplaintsResponse'];
    if (alt is List) return alt;
    return const [];
  }

  factory NearbyComplaintsListDataDto.fromDataJson(Map<String, dynamic> data) {
    final rawList = _extractList(data);
    final complaints = <NearbyComplaintDto>[];
    for (final item in rawList) {
      if (item is Map) {
        complaints.add(
          NearbyComplaintDto.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }
    final countRaw = data['count'];
    final count = countRaw is int
        ? countRaw
        : (countRaw is num ? countRaw.toInt() : null);
    return NearbyComplaintsListDataDto(
      complaints: complaints,
      count: count,
    );
  }
}
