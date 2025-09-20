// lib/models/user_profile.dart
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? employeeId;
  final String? department;
  final String? position;
  final UserRole role;
  final String? managerId;
  final DateTime? hireDate;
  final String? phone;
  final bool isActive;
  final Map<String, double> leaveBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.employeeId,
    this.department,
    this.position,
    required this.role,
    this.managerId,
    this.hireDate,
    this.phone,
    required this.isActive,
    required this.leaveBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      employeeId: json['employee_id'],
      department: json['department'],
      position: json['position'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.employee,
      ),
      managerId: json['manager_id'],
      hireDate: json['hire_date'] != null ? DateTime.parse(json['hire_date']) : null,
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      leaveBalance: Map<String, double>.from(json['leave_balance'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'employee_id': employeeId,
      'department': department,
      'position': position,
      'role': role.name,
      'manager_id': managerId,
      'hire_date': hireDate?.toIso8601String().split('T')[0],
      'phone': phone,
      'is_active': isActive,
      'leave_balance': leaveBalance,
    };
  }
}

enum UserRole { employee, manager, hr, admin }
