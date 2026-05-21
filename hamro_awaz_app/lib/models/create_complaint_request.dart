import 'package:equatable/equatable.dart';

class ComplaintCoordinates extends Equatable {
  const ComplaintCoordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  @override
  List<Object?> get props => [latitude, longitude];
}

class CreateComplaintRequest extends Equatable {
  const CreateComplaintRequest({
    required this.complaintTitle,
    required this.complaintDescription,
    required this.categoryId,
    required this.complaintCoordinates,
  });

  final String complaintTitle;
  final String complaintDescription;
  final String categoryId;
  final ComplaintCoordinates complaintCoordinates;

  Map<String, dynamic> toJson() => {
        'complaintTitle': complaintTitle,
        'complaintDescription': complaintDescription,
        'categoryId': categoryId,
        'complaintCoordinates': complaintCoordinates.toJson(),
      };

  @override
  List<Object?> get props =>
      [complaintTitle, complaintDescription, categoryId, complaintCoordinates];
}
