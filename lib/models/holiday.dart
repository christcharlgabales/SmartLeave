class Holiday {
  final String id;
  final String name;
  final DateTime date;
  final bool isRecurring;
  final String? description;
  final DateTime createdAt;

  Holiday({
    required this.id,
    required this.name,
    required this.date,
    required this.isRecurring,
    this.description,
    required this.createdAt,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      isRecurring: json['is_recurring'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date.toIso8601String().split('T')[0],
      'is_recurring': isRecurring,
      'description': description,
    };
  }
}