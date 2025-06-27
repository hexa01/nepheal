class Specialization {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  Specialization({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  // FIXED: Handle API response that only has id and name
  factory Specialization.fromJson(Map<String, dynamic> json) {
    try {
      return Specialization(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Unknown',
        // Use current time as placeholder if timestamps don't exist
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at']) 
            : DateTime.now(),
        updatedAt: json['updated_at'] != null 
            ? DateTime.parse(json['updated_at']) 
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing specialization: $e');
      print('JSON: $json');
      // Return safe default
      return Specialization(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Unknown',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}