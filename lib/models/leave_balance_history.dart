class LeaveBalanceHistory {
  final String id;
  final String userId;
  final String leaveTypeId;
  final double changeAmount;
  final double balanceAfter;
  final String reason;
  final String? referenceId;
  final String? createdBy;
  final DateTime createdAt;

  LeaveBalanceHistory({
    required this.id,
    required this.userId,
    required this.leaveTypeId,
    required this.changeAmount,
    required this.balanceAfter,
    required this.reason,
    this.referenceId,
    this.createdBy,
    required this.createdAt,
  });

  factory LeaveBalanceHistory.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceHistory(
      id: json['id'],
      userId: json['user_id'],
      leaveTypeId: json['leave_type_id'],
      changeAmount: double.parse(json['change_amount'].toString()),
      balanceAfter: double.parse(json['balance_after'].toString()),
      reason: json['reason'],
      referenceId: json['reference_id'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}