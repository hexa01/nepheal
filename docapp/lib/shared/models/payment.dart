class Payment {
  final int? id;
  final int appointmentId;
  final String? pid;
  final double amount;
  final String status; // 'unpaid', 'paid'
  final String? paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PaymentAppointment? appointment; // For when payment includes appointment data

  Payment({
    this.id,
    required this.appointmentId,
    this.pid,
    required this.amount,
    required this.status,
    this.paymentMethod,
    this.createdAt,
    this.updatedAt,
    this.appointment,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      appointmentId: json['appointment_id'],
      pid: json['pid'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
      paymentMethod: json['payment_method'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      appointment: json['appointment'] != null
          ? PaymentAppointment.fromJson(json['appointment'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'pid': pid,
      'amount': amount,
      'status': status,
      'payment_method': paymentMethod,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (appointment != null) 'appointment': appointment!.toJson(),
    };
  }

  // Helper methods
  bool get isPaid => status == 'paid';
  bool get isPending => status == 'unpaid';
  bool get canRetry => status == 'unpaid';
  
  String get formattedAmount => 'Rs. ${amount.toStringAsFixed(0)}';
  
  String get statusDisplay {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'unpaid':
        return 'Pending';
      default:
        return status.toUpperCase();
    }
  }

  // Copy with method
  Payment copyWith({
    int? id,
    int? appointmentId,
    String? pid,
    double? amount,
    String? status,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    PaymentAppointment? appointment,
  }) {
    return Payment(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      pid: pid ?? this.pid,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      appointment: appointment ?? this.appointment,
    );
  }

  @override
  String toString() {
    return 'Payment(id: $id, appointmentId: $appointmentId, amount: $amount, status: $status)';
  }
}

// Simplified appointment class for payment responses
class PaymentAppointment {
  final int id;
  final String date;
  final String slot;
  final String status;
  final PaymentDoctor? doctor;

  PaymentAppointment({
    required this.id,
    required this.date,
    required this.slot,
    required this.status,
    this.doctor,
  });

  factory PaymentAppointment.fromJson(Map<String, dynamic> json) {
    return PaymentAppointment(
      id: json['id'],
      date: json['date'],
      slot: json['slot'],
      status: json['status'],
      doctor: json['doctor'] != null
          ? PaymentDoctor.fromJson(json['doctor'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'slot': slot,
      'status': status,
      if (doctor != null) 'doctor': doctor!.toJson(),
    };
  }
}

class PaymentDoctor {
  final String name;
  final String specialization;

  PaymentDoctor({
    required this.name,
    required this.specialization,
  });

  factory PaymentDoctor.fromJson(Map<String, dynamic> json) {
    return PaymentDoctor(
      name: json['name'],
      specialization: json['specialization'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialization': specialization,
    };
  }
}

// Payment method model
class PaymentMethod {
  final String id;
  final String name;
  final bool available;
  final String logo;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.available,
    required this.logo,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      available: json['available'] ?? false,
      logo: json['logo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'available': available,
      'logo': logo,
    };
  }

  @override
  String toString() {
    return 'PaymentMethod(id: $id, name: $name, available: $available)';
  }
}

// Payment initiation response
class PaymentInitiation {
  final int paymentId;
  final double amount;
  final int appointmentId;
  final String paymentMethod;

  PaymentInitiation({
    required this.paymentId,
    required this.amount,
    required this.appointmentId,
    required this.paymentMethod,
  });

  factory PaymentInitiation.fromJson(Map<String, dynamic> json) {
    return PaymentInitiation(
      paymentId: json['payment_id'],
      amount: (json['amount'] as num).toDouble(),
      appointmentId: json['appointment_id'],
      paymentMethod: json['payment_method'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'amount': amount,
      'appointment_id': appointmentId,
      'payment_method': paymentMethod,
    };
  }
}