// lib/models/leave_request.dart
class LeaveRequest {
  final String id;
  final String userId;
  final String leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalDays;
  final String reason;
  final LeaveStatus status;
  final String? managerId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? managerComments;
  final String? attachmentUrl;
  final bool isHalfDay;
  final String? halfDayPeriod;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Related objects (populated via joins)
  final LeaveType? leaveType;
  final UserProfile? manager;
  final UserProfile? user;

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.managerId,
    this.approvedBy,
    this.approvedAt,
    this.managerComments,
    this.attachmentUrl,
    required this.isHalfDay,
    this.halfDayPeriod,
    required this.createdAt,
    required this.updatedAt,
    this.leaveType,
    this.manager,
    this.user,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'],
      userId: json['user_id'],
      leaveTypeId: json['leave_type_id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      totalDays: double.parse(json['total_days'].toString()),
      reason: json['reason'],
      status: LeaveStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LeaveStatus.pending,
      ),
      managerId: json['manager_id'],
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at']) 
          : null,
      managerComments: json['manager_comments'],
      attachmentUrl: json['attachment_url'],
      isHalfDay: json['is_half_day'] ?? false,
      halfDayPeriod: json['half_day_period'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      leaveType: json['leave_types'] != null 
          ? LeaveType.fromJson(json['leave_types']) 
          : null,
      manager: json['manager'] != null 
          ? UserProfile.fromJson(json['manager']) 
          : null,
      user: json['user'] != null 
          ? UserProfile.fromJson(json['user']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'leave_type_id': leaveTypeId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'total_days': totalDays,
      'reason': reason,
      'manager_id': managerId,
      'attachment_url': attachmentUrl,
      'is_half_day': isHalfDay,
      'half_day_period': halfDayPeriod,
    };
  }

  // Helper method to create a copy with updated fields
  LeaveRequest copyWith({
    String? id,
    LeaveStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? managerComments,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      userId: userId,
      leaveTypeId: leaveTypeId,
      startDate: startDate,
      endDate: endDate,
      totalDays: totalDays,
      reason: reason,
      status: status ?? this.status,
      managerId: managerId,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      managerComments: managerComments ?? this.managerComments,
      attachmentUrl: attachmentUrl,
      isHalfDay: isHalfDay,
      halfDayPeriod: halfDayPeriod,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      leaveType: leaveType,
      manager: manager,
      user: user,
    );
  }
}

enum LeaveStatus { pending, approved, rejected, cancelled }