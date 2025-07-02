class Message {
  final int id;
  final int appointmentId;
  final String doctorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    required this.id,
    required this.appointmentId,
    required this.doctorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      appointmentId: json['appointment_id'] is int ? json['appointment_id'] : int.tryParse(json['appointment_id'].toString()) ?? 0,
      doctorMessage: json['doctor_message']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'doctor_message': doctorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class PatientInfo {
  final int id;
  final String name;
  final String email;
  final String? phone;

  PatientInfo({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
    );
  }
}

class CompletedAppointment {
  final int id;
  final String appointmentDate;
  final String slot;
  final PatientInfo patient;
  final bool hasMessage;
  final Message? message;

  CompletedAppointment({
    required this.id,
    required this.appointmentDate,
    required this.slot,
    required this.patient,
    required this.hasMessage,
    this.message,
  });

  factory CompletedAppointment.fromJson(Map<String, dynamic> json) {
    return CompletedAppointment(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      appointmentDate: json['appointment_date']?.toString() ?? '',
      slot: json['slot']?.toString() ?? '',
      patient: PatientInfo.fromJson(json['patient'] ?? {}),
      hasMessage: json['has_message'] == true,
      message: json['message'] != null ? Message.fromJson(json['message']) : null,
    );
  }
}

class PatientMessage {
  final int id;
  final String doctorMessage;
  final DateTime createdAt;
  final PatientMessageAppointment appointment;

  PatientMessage({
    required this.id,
    required this.doctorMessage,
    required this.createdAt,
    required this.appointment,
  });

  factory PatientMessage.fromJson(Map<String, dynamic> json) {
    return PatientMessage(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      doctorMessage: json['doctor_message']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      appointment: PatientMessageAppointment.fromJson(json['appointment'] ?? {}),
    );
  }
}

class PatientMessageAppointment {
  final int id;
  final String appointmentDate;
  final String slot;
  final PatientMessageDoctor doctor;

  PatientMessageAppointment({
    required this.id,
    required this.appointmentDate,
    required this.slot,
    required this.doctor,
  });

  factory PatientMessageAppointment.fromJson(Map<String, dynamic> json) {
    return PatientMessageAppointment(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      appointmentDate: json['appointment_date']?.toString() ?? '',
      slot: json['slot']?.toString() ?? '',
      doctor: PatientMessageDoctor.fromJson(json['doctor'] ?? {}),
    );
  }
}

class PatientMessageDoctor {
  final String name;
  final String specialization;

  PatientMessageDoctor({
    required this.name,
    required this.specialization,
  });

  factory PatientMessageDoctor.fromJson(Map<String, dynamic> json) {
    return PatientMessageDoctor(
      name: json['name']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? 'General',
    );
  }
}