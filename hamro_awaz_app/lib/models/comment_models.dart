import 'complaint.dart';

class CreateCommentRequest {
  const CreateCommentRequest({
    required this.message,
    required this.complaintUniqueId,
  });

  final String message;
  final String complaintUniqueId;

  Map<String, dynamic> toJson() => {
        'message': message,
        'complaintUniqueId': complaintUniqueId,
      };
}

class ViewCommentsRequest {
  const ViewCommentsRequest({required this.complaintUniqueId});

  final String complaintUniqueId;

  Map<String, dynamic> toJson() => {
        'complaintUniqueId': complaintUniqueId,
      };
}

class UpdateCommentRequest {
  const UpdateCommentRequest({
    required this.message,
    required this.complaintUniqueId,
    required this.commentUniqueId,
  });

  final String message;
  final String complaintUniqueId;
  final String commentUniqueId;

  Map<String, dynamic> toJson() => {
        'message': message,
        'complaintUniqueId': complaintUniqueId,
        'commentUniqueId': commentUniqueId,
      };
}

class DeleteCommentRequest {
  const DeleteCommentRequest({
    required this.complaintUniqueId,
    required this.commentUniqueId,
  });

  final String complaintUniqueId;
  final String commentUniqueId;

  Map<String, dynamic> toJson() => {
        'complaintUniqueId': complaintUniqueId,
        'commentUniqueId': commentUniqueId,
      };
}

class CommentAuthor {
  const CommentAuthor({
    required this.fullName,
    required this.uniqueId,
    this.phoneNumber,
    this.profilePictureLink,
    this.isUserVerified = false,
  });

  final String fullName;
  final String? phoneNumber;
  final String uniqueId;
  final String? profilePictureLink;
  final bool isUserVerified;

  factory CommentAuthor.fromJson(Map<String, dynamic> json) {
    return CommentAuthor(
      fullName: json['fullName']?.toString() ?? 'Unknown',
      phoneNumber: json['phoneNumber']?.toString(),
      uniqueId: json['uniqueId']?.toString() ?? '',
      profilePictureLink: json['profilePictureLink']?.toString(),
      isUserVerified: json['isUserVerified'] == true,
    );
  }
}

class ComplaintComment {
  const ComplaintComment({
    required this.uniqueId,
    required this.message,
    required this.commentBy,
    required this.commentAt,
    this.updatedAt,
  });

  final String uniqueId;
  final String message;
  final CommentAuthor commentBy;
  final DateTime commentAt;
  final DateTime? updatedAt;

  bool get isEdited =>
      updatedAt != null && updatedAt!.isAfter(commentAt);

  factory ComplaintComment.fromJson(Map<String, dynamic> json) {
    return ComplaintComment(
      uniqueId: json['uniqueId']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      commentBy: CommentAuthor.fromJson(
        Map<String, dynamic>.from(
          json['commentBy'] as Map? ?? const {},
        ),
      ),
      commentAt:
          parseApiDateTime(json['commentAt']) ?? DateTime.now(),
      updatedAt: parseApiDateTime(json['updatedAt']),
    );
  }

  static List<ComplaintComment> listFromData(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => ComplaintComment.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.uniqueId.isNotEmpty)
        .toList();
  }
}
