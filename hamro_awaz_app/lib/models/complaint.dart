enum ComplaintStatus {
  pending,
  inProgress,
  resolved,
  escalated,
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
  final String? municipalityUniqueId;

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
    this.municipalityUniqueId,
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
    String? municipalityUniqueId,
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
      municipalityUniqueId: municipalityUniqueId ?? this.municipalityUniqueId,
    );
  }

  /// Parses one complaint object as returned by create / update / list nearby.
  factory Complaint.fromApiMap(
    Map<String, dynamic> json, {
    String currentUserId = '',
  }) {
    final id = json['complaintUniqueId']?.toString() ??
        json['id']?.toString() ??
        json['_id']?.toString() ??
        '';
    final title =
        json['complaintTitle']?.toString() ?? json['title']?.toString() ?? '';
    final description = json['complaintDescription']?.toString() ??
        json['description']?.toString() ??
        '';
    final catId = json['categoryId']?.toString();
    final category = complaintCategoryFromApiId(catId);
    final dept = json['municipality']?.toString() ??
        json['department']?.toString() ??
        json['municipalityName']?.toString() ??
        '';
    final status =
        complaintStatusFromApi(json['status']?.toString() ?? json['complaintStatus']?.toString());
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
    final munId = json['municipalityUniqueId']?.toString();

    var isOwn = json['isOwnSubmission'] == true ||
        json['ownComplaint'] == true ||
        json['isMine'] == true ||
        json['highlight'] == true ||
        json['highlighted'] == true ||
        json['userComplaint'] == true;
    if (currentUserId.isNotEmpty && userId.isNotEmpty && userId == currentUserId) {
      isOwn = true;
    }

    final created = DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.tryParse(json['createdDate']?.toString() ?? '') ??
        DateTime.now();
    final updated = DateTime.tryParse(json['updatedAt']?.toString() ?? '');

    final images = <String>[];
    final pu = json['photoUrl']?.toString();
    if (pu != null && pu.isNotEmpty) images.add(pu);
    final listUrl = json['imageUrls'];
    if (listUrl is List) {
      for (final e in listUrl) {
        final s = e.toString();
        if (s.isNotEmpty) images.add(s);
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
      municipalityUniqueId: munId,
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
      'municipalityUniqueId': municipalityUniqueId,
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
      municipalityUniqueId: json['municipalityUniqueId']?.toString(),
    );
  }

  String get categoryName {
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

