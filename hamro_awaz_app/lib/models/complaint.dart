import '../core/constants/api_constants.dart';

enum ComplaintStatus {
  pending,
  inProgress,
  resolved,
  escalated,
}

/// Municipality complaint category from `GET /municipality/category/list`.
class Category {
  const Category({
    required this.categoryName,
    required this.uniqueId,
  });

  final String categoryName;
  final String uniqueId;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryName: json['categoryName']?.toString() ?? '',
      uniqueId: json['uniqueId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryName': categoryName,
        'uniqueId': uniqueId,
      };

  /// Parses `data` array from the standard API envelope.
  static List<Category> listFromEnvelopeData(dynamic data) {
    if (data is! List) return [];
    final out = <Category>[];
    for (final item in data) {
      if (item is Map) {
        final category = Category.fromJson(Map<String, dynamic>.from(item));
        if (category.uniqueId.isNotEmpty && category.categoryName.isNotEmpty) {
          out.add(category);
        }
      }
    }
    return out;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          categoryName == other.categoryName &&
          uniqueId == other.uniqueId;

  @override
  int get hashCode => Object.hash(categoryName, uniqueId);
}

enum ComplaintCategory {
  infrastructure,
  sanitation,
  waterSupply,
  electricity,
  road,
  wasteManagement,
  other,
}

/// Backend `categoryId` strings — replace with UUIDs from your environment if required.
extension ComplaintCategoryApiId on ComplaintCategory {
  String get apiCategoryId {
    switch (this) {
      case ComplaintCategory.infrastructure:
        return 'infrastructure';
      case ComplaintCategory.sanitation:
        return 'sanitation';
      case ComplaintCategory.waterSupply:
        return 'water_supply';
      case ComplaintCategory.electricity:
        return 'electricity';
      case ComplaintCategory.road:
        return 'road';
      case ComplaintCategory.wasteManagement:
        return 'waste_management';
      case ComplaintCategory.other:
        return 'other';
    }
  }

}

ComplaintCategory complaintCategoryFromApiId(String? id) {
  if (id == null || id.isEmpty) return ComplaintCategory.other;
  for (final c in ComplaintCategory.values) {
    if (c.apiCategoryId == id) return c;
  }
  return ComplaintCategory.other;
}

ComplaintStatus complaintStatusFromApi(String? raw) {
  if (raw == null || raw.isEmpty) return ComplaintStatus.pending;
  switch (raw.toUpperCase().replaceAll(' ', '')) {
    case 'NEW':
      return ComplaintStatus.pending;
    case 'PENDING':
      return ComplaintStatus.pending;
    case 'INPROGRESS':
    case 'IN_PROGRESS':
    case 'IN-PROGRESS':
      return ComplaintStatus.inProgress;
    case 'RESOLVED':
    case 'CLOSED':
      return ComplaintStatus.resolved;
    case 'ESCALATED':
      return ComplaintStatus.escalated;
    default:
      return ComplaintStatus.pending;
  }
}

/// Backend `param.status` value for [SearchParam].
String complaintStatusToApiParam(ComplaintStatus status) {
  switch (status) {
    case ComplaintStatus.pending:
      return 'NEW';
    case ComplaintStatus.inProgress:
      return 'IN_PROGRESS';
    case ComplaintStatus.resolved:
      return 'RESOLVED';
    case ComplaintStatus.escalated:
      return 'ESCALATED';
  }
}

DateTime? parseApiDateTime(dynamic raw) {
  if (raw is List && raw.length >= 3) {
    try {
      final y = (raw[0] as num).toInt();
      final m = (raw[1] as num).toInt();
      final d = (raw[2] as num).toInt();
      final h = raw.length > 3 ? (raw[3] as num).toInt() : 0;
      final min = raw.length > 4 ? (raw[4] as num).toInt() : 0;
      final sec = raw.length > 5 ? (raw[5] as num).toInt() : 0;
      return DateTime(y, m, d, h, min, sec);
    } catch (_) {
      return null;
    }
  }
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw);
  }
  return null;
}

class Complaint {
  final String id;
  final String title;
  final String description;
  final ComplaintCategory category;
  final String department;
  final ComplaintStatus status;
  final String userId;
  final List<String> imageUrls;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int yesVotes;
  final int noVotes;
  final bool userHasVoted;
  final String? userVote;
  /// From `list/nearBy` when logged in — backend marks the citizen's submissions.
  final bool isOwnSubmission;
  /// Raw category id from API when known (for updates).
  final String? categoryIdStr;
  /// Display label from API (`categoryName`), when available.
  final String? categoryLabel;
  /// Status description from API (`status.description`).
  final String? statusLabel;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.department,
    required this.status,
    required this.userId,
    this.imageUrls = const [],
    this.latitude,
    this.longitude,
    this.address,
    required this.createdAt,
    this.updatedAt,
    this.yesVotes = 0,
    this.noVotes = 0,
    this.userHasVoted = false,
    this.userVote,
    this.isOwnSubmission = false,
    this.categoryIdStr,
    this.categoryLabel,
    this.statusLabel,
  });

  Complaint copyWith({
    String? id,
    String? title,
    String? description,
    ComplaintCategory? category,
    String? department,
    ComplaintStatus? status,
    String? userId,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? yesVotes,
    int? noVotes,
    bool? userHasVoted,
    String? userVote,
    bool? isOwnSubmission,
    String? categoryIdStr,
    String? categoryLabel,
    String? statusLabel,
  }) {
    return Complaint(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      department: department ?? this.department,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      imageUrls: imageUrls ?? this.imageUrls,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      yesVotes: yesVotes ?? this.yesVotes,
      noVotes: noVotes ?? this.noVotes,
      userHasVoted: userHasVoted ?? this.userHasVoted,
      userVote: userVote ?? this.userVote,
      isOwnSubmission: isOwnSubmission ?? this.isOwnSubmission,
      categoryIdStr: categoryIdStr ?? this.categoryIdStr,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      statusLabel: statusLabel ?? this.statusLabel,
    );
  }

  /// Parses one complaint object as returned by create / update / list / my complaints.
  factory Complaint.fromApiMap(
    Map<String, dynamic> json, {
    String currentUserId = '',
    bool markAsOwnSubmission = false,
  }) {
    final id = json['uniqueId']?.toString() ??
        json['complaintUniqueId']?.toString() ??
        json['id']?.toString() ??
        json['_id']?.toString() ??
        '';
    final title =
        json['complaintTitle']?.toString() ?? json['title']?.toString() ?? '';
    final description = json['complaintDescription']?.toString() ??
        json['description']?.toString() ??
        '';
    final catId = json['categoryId']?.toString();
    var catLabel = json['categoryName']?.toString();
    final categoryObj = json['category'];
    if (categoryObj is Map) {
      final cat = Map<String, dynamic>.from(categoryObj);
      final name = cat['name']?.toString();
      final desc = cat['description']?.toString();
      if (name != null && name.isNotEmpty) {
        catLabel = name;
      } else if (desc != null && desc.isNotEmpty) {
        catLabel = desc;
      }
    }
    final category = complaintCategoryFromApiId(catId);
    final dept = json['municipality']?.toString() ??
        json['department']?.toString() ??
        json['municipalityName']?.toString() ??
        '';

    String? statusRaw;
    String? statusDescription;
    final statusObj = json['status'];
    if (statusObj is Map) {
      final st = Map<String, dynamic>.from(statusObj);
      statusRaw = st['name']?.toString();
      statusDescription = st['description']?.toString();
    } else {
      statusRaw =
          json['status']?.toString() ?? json['complaintStatus']?.toString();
    }
    final status = complaintStatusFromApi(statusRaw);
    final coords = json['complaintCoordinates'];
    double? lat = (json['latitude'] as num?)?.toDouble();
    double? lng = (json['longitude'] as num?)?.toDouble();
    if (coords is Map) {
      final cm = Map<String, dynamic>.from(coords);
      lat = (cm['latitude'] as num?)?.toDouble() ?? lat;
      lng = (cm['longitude'] as num?)?.toDouble() ?? lng;
    }
    final userId =
        json['userId']?.toString() ?? json['submittedByUserId']?.toString() ?? '';

    var isOwn = markAsOwnSubmission ||
        json['isOwnSubmission'] == true ||
        json['ownComplaint'] == true ||
        json['isMine'] == true ||
        json['highlight'] == true ||
        json['highlighted'] == true ||
        json['userComplaint'] == true;
    if (currentUserId.isNotEmpty && userId.isNotEmpty && userId == currentUserId) {
      isOwn = true;
    }

    final created = parseApiDateTime(json['createdDate']) ??
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.tryParse(json['createdDate']?.toString() ?? '') ??
        DateTime.now();
    final updated = DateTime.tryParse(json['updatedAt']?.toString() ?? '');

    final images = <String>[];
    final pu = json['photoUrl']?.toString();
    if (pu != null && pu.isNotEmpty) {
      images.add(ApiConstants.resolveMediaUrl(pu));
    }
    final listUrl = json['imageUrls'];
    if (listUrl is List) {
      for (final e in listUrl) {
        final s = e.toString();
        if (s.isNotEmpty) images.add(ApiConstants.resolveMediaUrl(s));
      }
    }

    return Complaint(
      id: id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : id,
      title: title,
      description: description,
      category: category,
      department: dept,
      status: status,
      userId: userId.isEmpty ? '0' : userId,
      imageUrls: images,
      latitude: lat,
      longitude: lng,
      address: json['address']?.toString(),
      createdAt: created,
      updatedAt: updated,
      isOwnSubmission: isOwn,
      categoryIdStr: catId,
      categoryLabel: catLabel,
      statusLabel: statusDescription,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'department': department,
      'status': status.name,
      'userId': userId,
      'imageUrls': imageUrls,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'yesVotes': yesVotes,
      'noVotes': noVotes,
      'userHasVoted': userHasVoted,
      'userVote': userVote,
      'isOwnSubmission': isOwnSubmission,
      'categoryIdStr': categoryIdStr,
      'categoryLabel': categoryLabel,
      'statusLabel': statusLabel,
    };
  }

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: ComplaintCategory.values.firstWhere(
        (e) => e.name == json['category']?.toString(),
        orElse: () => ComplaintCategory.other,
      ),
      department: json['department']?.toString() ?? '',
      status: ComplaintStatus.values.firstWhere(
        (e) => e.name == json['status']?.toString(),
        orElse: () => ComplaintStatus.pending,
      ),
      userId: json['userId']?.toString() ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      yesVotes: (json['yesVotes'] as num?)?.toInt() ?? 0,
      noVotes: (json['noVotes'] as num?)?.toInt() ?? 0,
      userHasVoted: json['userHasVoted'] == true,
      userVote: json['userVote']?.toString(),
      isOwnSubmission: json['isOwnSubmission'] == true,
      categoryIdStr: json['categoryIdStr']?.toString(),
      categoryLabel: json['categoryLabel']?.toString(),
      statusLabel: json['statusLabel']?.toString(),
    );
  }

  String get categoryName {
    if (categoryLabel != null && categoryLabel!.isNotEmpty) {
      return categoryLabel!;
    }
    switch (category) {
      case ComplaintCategory.infrastructure:
        return 'Infrastructure';
      case ComplaintCategory.sanitation:
        return 'Sanitation';
      case ComplaintCategory.waterSupply:
        return 'Water Supply';
      case ComplaintCategory.electricity:
        return 'Electricity';
      case ComplaintCategory.road:
        return 'Road';
      case ComplaintCategory.wasteManagement:
        return 'Waste Management';
      case ComplaintCategory.other:
        return 'Other';
    }
  }

  String get statusName {
    if (statusLabel != null && statusLabel!.isNotEmpty) {
      return statusLabel!;
    }
    switch (status) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.escalated:
        return 'Escalated';
    }
  }
}

