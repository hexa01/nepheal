import 'user.dart';
import 'specialization.dart';

class Doctor {
  final int id;
  final int userId;
  final int? specializationId;
  final double hourlyRate;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;
  final Specialization? specialization;

  Doctor({
    required this.id,
    required this.userId,
    this.specializationId,
    required this.hourlyRate,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.specialization,
  });

  // For your doctors list API response
  factory Doctor.fromListJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>;

    return Doctor(
      id: json['id'],
      userId: 0, // Not provided in list API
      specializationId: null, // Not directly provided
      hourlyRate: 0.0, // Not provided in list API
      bio: null,
      createdAt: DateTime.now(), // Placeholder
      updatedAt: DateTime.now(), // Placeholder
      user: User(
        id: 0, // Not provided in list API
        name: userData['name'] ?? '',
        email: userData['email'] ?? '',
        role: userData['role'] ?? 'doctor',
        address: userData['address'],
        phone: userData['phone'],
        gender: 'male', // Placeholder - not in your API response
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      specialization: Specialization(
        id: 0, // Not provided
        name: userData['specialization'] ?? 'General',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  // Keep your existing fromJson for other API responses
  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      userId: json['user_id'],
      specializationId: json['specialization_id'],
      hourlyRate: double.parse(json['hourly_rate'].toString()),
      bio: json['bio'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      specialization: json['specialization'] != null
          ? Specialization.fromJson(json['specialization'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'specialization_id': specializationId,
      'hourly_rate': hourlyRate,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': user?.toJson(),
      'specialization': specialization?.toJson(),
    };
  }

  // Helper getters for easy UI access
  String get name => user?.name ?? 'Unknown';
  String get email => user?.email ?? '';
  String? get phone => user?.phone;
  String? get address => user?.address;
  String get specializationName => specialization?.name ?? 'General';
}
