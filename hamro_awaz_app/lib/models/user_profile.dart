import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.isUserVerified,
    this.profilePictureLink,
  });

  final String fullName;
  final String email;
  final String phoneNumber;
  final String? profilePictureLink;
  final bool isUserVerified;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      profilePictureLink: json['profilePictureLink']?.toString(),
      isUserVerified: json['isUserVerified'] == true ||
          json['isUserVerified']?.toString().toLowerCase() == 'true',
    );
  }

  @override
  List<Object?> get props =>
      [fullName, email, phoneNumber, profilePictureLink, isUserVerified];
}
