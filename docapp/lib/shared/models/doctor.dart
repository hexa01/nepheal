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

  // FIXED: Better null handling for your doctors list API response
  factory Doctor.fromListJson(Map<String, dynamic> json) {
    try {
      final userData = json['user'] as Map<String, dynamic>? ?? {};

      return Doctor(
        id: json['id'] ?? 0,
        userId: userData['id'] ?? 0, // Now properly extracted
        specializationId: json['specialization_id'],
        hourlyRate:
            double.tryParse(json['hourly_rate']?.toString() ?? '0') ?? 0.0,
        bio: json['bio'],
        createdAt: DateTime.now(), // Placeholder
        updatedAt: DateTime.now(), // Placeholder
        user: User(
          id: userData['id'] ?? 0,
          name: userData['name'] ?? 'Unknown Doctor',
          email: userData['email'] ?? '',
          role: userData['role'] ?? 'doctor',
          address: userData['address'], // Can be null
          phone: userData['phone'], // Can be null
          gender: 'male', // Placeholder
          profilePhoto: userData['profile_photo'],
          profilePhotoUrl: userData['profile_photo_url'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        specialization: Specialization(
          id: json['specialization_id'] ?? 0,
          name: userData['specialization'] ?? 'General',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Error parsing doctor from list JSON: $e');
      print('JSON data: $json');
      // Return a safe default doctor
      return Doctor(
        id: json['id'] ?? 0,
        userId: 0,
        specializationId: null,
        hourlyRate: 0.0,
        bio: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        user: User(
          id: 0,
          name: 'Unknown Doctor',
          email: '',
          role: 'doctor',
          address: null,
          phone: null,
          gender: 'male',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        specialization: Specialization(
          id: 0,
          name: 'General',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
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
  String get name => user?.name ?? 'Unknown Doctor';
  String get email => user?.email ?? '';
  String? get phone => user?.phone;
  String? get address => user?.address;
  String get specializationName => specialization?.name ?? 'General';
}
