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
}
