class Schedule {
  final int? id;
  final int doctorId;
  final String day;
  final String startTime;
  final String endTime;
  final int slot_count;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Schedule({
    this.id,
    required this.doctorId,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.slot_count,
    this.status = 'available',
    this.createdAt,
    this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      doctorId: json['doctor_id'] ?? 0,
      day: json['day'] ?? '',
      startTime: json['start_time'] ?? '10:00',
      endTime: json['end_time'] ?? '17:00',
      slot_count: json['slot_count'] ?? 14,
      status: json['status'] ?? 'available',
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
      'doctor_id': doctorId,
      'day': day,
      'start_time': startTime,
      'end_time': endTime,
      'slot_count': slot_count,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper methods
  String get displayDay {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'Mon';
      case 'tuesday':
        return 'Tue';
      case 'wednesday':
        return 'Wed';
      case 'thursday':
        return 'Thu';
      case 'friday':
        return 'Fri';
      case 'saturday':
        return 'Sat';
      case 'sunday':
        return 'Sun';
      default:
        return day;
    }
  }

  String get fullDayName {
    return day.substring(0, 1).toUpperCase() + day.substring(1).toLowerCase();
  }

  bool get isActive => status.toLowerCase() == 'available';

  // Calculate duration in hours
  double get durationHours {
    try {
      final start = _timeToMinutes(startTime);
      final end = _timeToMinutes(endTime);
      return (end - start) / 60.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Calculate slots based on 30-minute intervals
  int get calculatedSlots {
    try {
      final start = _timeToMinutes(startTime);
      final end = _timeToMinutes(endTime);
      return ((end - start) / 30).floor();
    } catch (e) {
      return 0;
    }
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (e) {
      return time24;
    }
  }

  String get timeRange => '${formatTime(startTime)} - ${formatTime(endTime)}';

  // Create a copy with updated fields
  Schedule copyWith({
    int? id,
    int? doctorId,
    String? day,
    String? startTime,
    String? endTime,
    int? slot_count,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      slot_count: slot_count ?? this.slot_count,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
