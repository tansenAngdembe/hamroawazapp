enum UserRole {
  citizen,
  admin,
}

class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.profileImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['uniqueId']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() == 'admin' 
          ? UserRole.admin 
          : UserRole.citizen,
      profileImageUrl: json['profileImageUrl']?.toString(),
    );
  }
}

