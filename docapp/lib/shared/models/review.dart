class Review {
  final int id;
  final int patientId;
  final int doctorId;
  final int appointmentId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? patientName;
  final String? patientInitials;
  final String? doctorName;
  final DateTime? appointmentDate;

  Review({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.patientName,
    this.patientInitials,
    this.doctorName,
    this.appointmentDate,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      patientId: json['patient_id'] ?? 0,
      doctorId: json['doctor_id'] ?? 0,
      appointmentId: json['appointment_id'] ?? 0,
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      patientName: json['patient_name'],
      patientInitials: json['patient_initials'],
      doctorName: json['doctor_name'],
      appointmentDate: json['appointment_date'] != null
          ? DateTime.parse(json['appointment_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'appointment_id': appointmentId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'patient_name': patientName,
      'patient_initials': patientInitials,
      'doctor_name': doctorName,
      'appointment_date': appointmentDate?.toIso8601String(),
    };
  }
}

class ReviewableAppointment {
  final int id;
  final DateTime appointmentDate;
  final String slot;
  final DoctorInfo doctor;

  ReviewableAppointment({
    required this.id,
    required this.appointmentDate,
    required this.slot,
    required this.doctor,
  });

  factory ReviewableAppointment.fromJson(Map<String, dynamic> json) {
    return ReviewableAppointment(
      id: json['id'] ?? 0,
      appointmentDate: DateTime.parse(json['appointment_date']),
      slot: json['slot'] ?? '',
      doctor: DoctorInfo.fromJson(json['doctor'] ?? {}),
    );
  }
}

class DoctorInfo {
  final int id;
  final String name;
  final String specialization;

  DoctorInfo({
    required this.id,
    required this.name,
    required this.specialization,
  });

  factory DoctorInfo.fromJson(Map<String, dynamic> json) {
    return DoctorInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Doctor',
      specialization: json['specialization'] ?? 'General',
    );
  }
}

class DoctorRatingStats {
  final int totalReviews;
  final double averageRating;
  final Map<int, int> ratingBreakdown;

  DoctorRatingStats({
    required this.totalReviews,
    required this.averageRating,
    required this.ratingBreakdown,
  });

  factory DoctorRatingStats.fromJson(Map<String, dynamic> json) {
    final breakdown = <int, int>{};
    final ratingData = json['rating_breakdown'] as Map<String, dynamic>? ?? {};

    for (int i = 1; i <= 5; i++) {
      breakdown[i] =
          int.tryParse(ratingData[i.toString()]?.toString() ?? '0') ?? 0;
    }

    return DoctorRatingStats(
      totalReviews: json['total_reviews'] ?? 0,
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      ratingBreakdown: breakdown,
    );
  }
}
