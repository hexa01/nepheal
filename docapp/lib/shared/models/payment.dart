class Payment {
  final int? id;
  final int appointmentId;
  final String? pid;
  final double amount;
  final String status; // 'unpaid', 'paid', if failed then status is unpaid
  final String? paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Payment({
    this.id,
    required this.appointmentId,
    this.pid,
    required this.amount,
    required this.status,
    this.paymentMethod,
    this.createdAt,
    this.updatedAt,
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
    };
  }

  // Helper methods
  bool get isPaid => status == 'paid';
  bool get isPending => status == 'unpaid';
  bool get isFailed => status == 'unpaid'; //can't change migration and model in backend now, can remove this if not needed

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
    );
  }

  @override
  String toString() {
    return 'Payment(id: $id, appointmentId: $appointmentId, amount: $amount, status: $status)';
  }
}
