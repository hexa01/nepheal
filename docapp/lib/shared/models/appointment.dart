import 'doctor.dart';
import 'patient.dart';

class Appointment {
  final int id;
  final int patientId;
  final int doctorId;
  final DateTime appointmentDate;
  final String slot;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Doctor? doctor;
  final Patient? patient;
  final double amount;
  final String paymentStatus;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentDate,
    required this.slot,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.doctor,
    this.patient,
    this.amount = 0.0,
    this.paymentStatus = 'unpaid',
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      slot: json['slot'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
      patient:
          json['patient'] != null ? Patient.fromJson(json['patient']) : null,
      amount: (json['amount'] != null)
          ? (json['amount'] is int
              ? (json['amount'] as int).toDouble()
              : json['amount'] as double)
          : 0.0,
      paymentStatus: json['payment_status'] ?? 'unpaid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'appointment_date': appointmentDate.toIso8601String().split('T')[0],
      'slot': slot,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'doctor': doctor?.toJson(),
      'patient': patient?.toJson(),
      'amount': amount,
      'payment_status': paymentStatus,
    };
  }
}
