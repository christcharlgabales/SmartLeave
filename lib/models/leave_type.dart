// lib/models/leave_type.dart
class LeaveType {
  final String id;
  final String name;
  final int annualAllocation;
  final bool carryForwardAllowed;
  final String? description;
  final String color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeaveType({
    required this.id,
    required this.name,
    required this.annualAllocation,
    required this.carryForwardAllowed,
    this.description,
    required this.color,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['id'],
      name: json['name'],
      annualAllocation: json['annual_allocation'],
      carryForwardAllowed: json['carry_forward_allowed'],
      description: json['description'],
      color: json['color'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'annual_allocation': annualAllocation,
      'carry_forward_allowed': carryForwardAllowed,
      'description': description,
      'color': color,
      'is_active': isActive,
    };
  }
}