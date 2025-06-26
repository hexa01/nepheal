import 'user.dart';

class Patient {
  final int id;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;

  Patient({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}
