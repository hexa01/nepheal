class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? address;
  final String? phone;
  final String gender;
  final String? profilePhoto;
  final String? profilePhotoUrl;
  final DateTime? dob;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.address,
    this.phone,
    required this.gender,
    this.profilePhoto,
    this.profilePhotoUrl,
    this.dob,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      address: json['address'],
      phone: json['phone'],
      gender: json['gender'],
      profilePhoto: json['profile_photo'],
      profilePhotoUrl: json['profile_photo_url'],
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      emailVerifiedAt: json['email_verified_at'] != null 
          ? DateTime.parse(json['email_verified_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'address': address,
      'phone': phone,
      'gender': gender,
      'profile_photo': profilePhoto,
      'profile_photo_url': profilePhotoUrl,
      'dob': dob?.toIso8601String(),
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method to get user initials for avatar fallback
  String get initials {
    final nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase() : 'U';
  }

  // Create a copy of the user with updated fields
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? address,
    String? phone,
    String? gender,
    String? profilePhoto,
    String? profilePhotoUrl,
    DateTime? dob,
    DateTime? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      dob: dob ?? this.dob,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if user has a profile photo
  bool get hasProfilePhoto => profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty;

  // Get display name for UI
  String get displayName => name.isNotEmpty ? name : 'Unknown User';

  // Get role display text
  String get roleDisplayText {
    switch (role.toLowerCase()) {
      case 'patient':
        return 'Patient';
      case 'doctor':
        return 'Doctor';
      case 'admin':
        return 'Administrator';
      default:
        return role.toUpperCase();
    }
  }
}